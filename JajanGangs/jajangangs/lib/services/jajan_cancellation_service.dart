import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/auth_session.dart';

class JajanCancellationFailure implements Exception {
  const JajanCancellationFailure(this.messageKey, this.stage, this.code);
  final String messageKey;
  final String stage;
  final String code;

  @override
  String toString() =>
      'JajanCancellationFailure(stage=$stage, code=$code, key=$messageKey)';
}

class JajanCancellationService {
  final _db = FirebaseFirestore.instance;
  static final Map<String, Future<void>> _running = {};

  void _log(String message) {
    if (kDebugMode) debugPrint('[JajanCancel] $message');
  }

  Future<void> cancel(String id, String uid) async {
    final key = '$uid/$id';
    final running = _running[key];
    if (running != null) return running;
    // Share the entire operation, including retries and final confirmation.
    final operation = _complete(id, uid);
    _running[key] = operation;
    try {
      await operation;
      _log('Cancellation completed; deletion confirmed.');
    } catch (error, stack) {
      _log('Cancellation failed: $error');
      if (kDebugMode) debugPrintStack(stackTrace: stack);
      rethrow;
    } finally {
      if (identical(_running[key], operation)) _running.remove(key);
    }
  }

  Future<T> _retry<T>(String stage, Future<T> Function() operation) async {
    for (var attempt = 0; ; attempt++) {
      try {
        _log('stage=$stage attempt=${attempt + 1} started');
        final result = await operation().timeout(const Duration(seconds: 20));
        _log('stage=$stage attempt=${attempt + 1} completed');
        return result;
      } catch (error, stack) {
        final code = error is JajanCancellationFailure
            ? error.code
            : error is FirebaseException
            ? error.code
            : error is TimeoutException
            ? 'deadline-exceeded'
            : error.runtimeType.toString();
        _log('stage=$stage code=$code attempt=${attempt + 1} error=$error');
        if (kDebugMode) debugPrintStack(stackTrace: stack);
        if (error is AuthFailure) rethrow;
        final temporary = [
          'unavailable',
          'deadline-exceeded',
          'aborted',
          'cancelled',
          'internal',
          'unknown',
          'resource-exhausted',
          'unconfirmed-state',
          'event-still-present',
        ].contains(code);
        if (temporary && attempt < 2) {
          await Future<void>.delayed(
            Duration(milliseconds: attempt == 0 ? 400 : 1000),
          );
          continue;
        }
        if (error is JajanCancellationFailure) rethrow;
        throw JajanCancellationFailure(
          code == 'permission-denied'
              ? 'eventCancelPermission'
              : code == 'unauthenticated'
              ? 'signInAgain'
              : temporary
              ? 'eventCancelConnection'
              : 'eventCancelFailed',
          stage,
          code,
        );
      }
    }
  }

  Future<void> _complete(String id, String uid) async {
    try {
      await _cancel(id, uid);
    } on JajanCancellationFailure {
      // Another device or a timed-out write may already have completed deletion.
      // A failed verification must not overwrite the original diagnostic.
      var gone = false;
      try {
        final snapshot = await _db
            .collection('jajan_events')
            .doc(id)
            .get(const GetOptions(source: Source.server))
            .timeout(const Duration(seconds: 10));
        gone = !snapshot.exists && !snapshot.metadata.hasPendingWrites;
        _log(
          'recovery-confirmation exists=${snapshot.exists} '
          'pendingWrites=${snapshot.metadata.hasPendingWrites}',
        );
      } catch (error, stack) {
        _log('recovery-confirmation error=$error');
        if (kDebugMode) debugPrintStack(stackTrace: stack);
      }
      if (!gone) rethrow;
    }
    try {
      final preferences = SharedPreferencesAsync();
      final key = 'pending_jajan_$uid';
      final value = await preferences.getString(key);
      if (value != null && (jsonDecode(value) as Map)['id'] == id)
        await preferences.remove(key);
    } catch (_) {
      /* Confirmed remote deletion is not undone by a local cache error. */
    }
  }

  Future<void> _cancel(String id, String uid) async {
    if (FirebaseAuth.instance.currentUser?.uid != uid)
      throw const AuthFailure('signInAgain');
    final ref = _db.collection('jajan_events').doc(id);
    final slot = _db.collection('active_jajan_slots').doc(uid);
    await _retry(
      'mark-cancelling',
      () => _db.runTransaction((tx) async {
        final event = await tx.get(ref);
        final active = await tx.get(slot);
        if (!event.exists) return;
        if (event.data()?['creatorId'] != uid)
          throw const AuthFailure('jajanPermission');
        // Durable cancellation intent: joins/decisions stop before child deletion.
        if (event.data()?['state'] != 'CANCELLING') {
          tx.update(ref, {
            'state': 'CANCELLING',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
        if (active.exists) {
          final data = active.data()!;
          final legacy = List<String>.from(data['legacyEventIds'] as List);
          final hadLegacy = legacy.remove(id);
          if (data['eventId'] == id || hadLegacy) {
            tx.update(slot, {
              'eventId': data['eventId'] == id ? '' : data['eventId'],
              'legacyEventIds': legacy,
              'legacyUntil': legacy.isEmpty
                  ? Timestamp.fromMillisecondsSinceEpoch(0)
                  : data['legacyUntil'],
            });
          }
        }
      }),
    );
    final marked = await _retry('confirm-cancelling', () async {
      final snapshot = await ref.get(const GetOptions(source: Source.server));
      _log(
        'confirm-cancelling exists=${snapshot.exists} '
        'state=${snapshot.data()?['state']} '
        'fromCache=${snapshot.metadata.isFromCache} '
        'pendingWrites=${snapshot.metadata.hasPendingWrites}',
      );
      if (snapshot.metadata.isFromCache ||
          snapshot.metadata.hasPendingWrites ||
          (snapshot.exists && snapshot.data()?['state'] != 'CANCELLING')) {
        throw const JajanCancellationFailure(
          'eventCancelFailed',
          'confirm-cancelling',
          'unconfirmed-state',
        );
      }
      return snapshot;
    });
    if (!marked.exists) return;

    // Freeze writes first, delete every child collection, then delete the parent.
    for (final collection in [
      'join_requests',
      'messages',
      'polls',
      'wheels',
      'wheel_history',
      'chat_state',
      'chat_summary',
      'event_notifications',
    ]) {
      while (true) {
        final page = await _retry(
          'read-$collection',
          () => ref
              .collection(collection)
              .limit(10)
              .get(const GetOptions(source: Source.server)),
        );
        if (page.docs.isEmpty) break;
        await _retry('delete-$collection', () async {
          // Fresh batch on each retry; repeating a delete is safe.
          final batch = _db.batch();
          for (final doc in page.docs) {
            batch.delete(doc.reference);
          }
          await batch.commit();
        });
      }
    }
    await _retry('delete-event', () => ref.delete());
    await _retry('confirm-deletion', () async {
      final remaining = await ref.get(const GetOptions(source: Source.server));
      _log(
        'confirm-deletion exists=${remaining.exists} '
        'fromCache=${remaining.metadata.isFromCache} '
        'pendingWrites=${remaining.metadata.hasPendingWrites}',
      );
      if (remaining.exists ||
          remaining.metadata.hasPendingWrites ||
          remaining.metadata.isFromCache) {
        throw const JajanCancellationFailure(
          'eventCancelFailed',
          'confirm-deletion',
          'event-still-present',
        );
      }
    });
  }

  /// Called on Home entry/refresh. The parent remains until cleanup completes,
  /// so cancellation can recover even after app termination or on another device.
  Future<void> resume(String uid) async {
    while (true) {
      final page = await _db
          .collection('jajan_events')
          .where('creatorId', isEqualTo: uid)
          .where('state', isEqualTo: 'CANCELLING')
          .limit(20)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 15));
      if (page.docs.isEmpty) return;
      for (final doc in page.docs) {
        await cancel(doc.id, uid);
      }
    }
  }
}
