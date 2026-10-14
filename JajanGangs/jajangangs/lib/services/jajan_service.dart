import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_session.dart';
import '../models/home_map_state.dart';
import '../models/jajan_event.dart';

class JajanService {
  final _preferences = SharedPreferencesAsync();
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  String _key(String uid) => 'pending_jajan_$uid';
  void _requireUser(String uid) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.uid != uid || !user.emailVerified)
      throw const AuthFailure('signInAgain');
  }

  DocumentReference<Map<String, dynamic>> slot(String uid) =>
      _db.collection('active_jajan_slots').doc(uid);

  bool _legacyBlocked(Map<String, dynamic>? data) =>
      (data?['legacyUntil'] as Timestamp?)?.toDate().isAfter(
        DateTime.now().toUtc(),
      ) ??
      false;

  /// Server reads before opening the form. Never route to an existing event.
  Future<void> ensureCanCreate(String uid, {String? retryId}) async {
    _requireUser(uid);
    try {
      final record = await slot(uid)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 15));
      final current = record.data()?['eventId'] as String?;
      if (current != null && current.isNotEmpty && current != retryId) {
        final event = decode(
          await _db
              .collection('jajan_events')
              .doc(current)
              .get(const GetOptions(source: Source.server))
              .timeout(const Duration(seconds: 15)),
        );
        if (event?.isActive ?? false)
          throw const AuthFailure('jajanAlreadyActive');
      }
      if (_legacyBlocked(record.data()))
        throw const AuthFailure('jajanAlreadyActive');
      // Also checks pre-migration events, paging rather than just taking the newest 20.
      DocumentSnapshot<Map<String, dynamic>>? cursor;
      while (true) {
        Query<Map<String, dynamic>> query = _db
            .collection('jajan_events')
            .where('creatorId', isEqualTo: uid)
            .orderBy('createdAt', descending: true);
        if (cursor != null) query = query.startAfterDocument(cursor);
        final page = await query
            .limit(20)
            .get(const GetOptions(source: Source.server))
            .timeout(const Duration(seconds: 15));
        for (final doc in page.docs) {
          final event = decode(doc);
          if (event != null && event.id != retryId && event.isActive) {
            throw const AuthFailure('jajanAlreadyActive');
          }
        }
        if (page.docs.length < 20) break;
        final oldest = decode(page.docs.last);
        if (oldest != null && !oldest.expiresAt.isAfter(DateTime.now().toUtc()))
          break;
        cursor = page.docs.last;
      }
    } on AuthFailure {
      rethrow;
    } catch (_) {
      throw const AuthFailure('jajanActiveCheckFailed');
    }
  }

  Future<JajanDraft?> restoreDraft(String uid) async {
    _requireUser(uid);
    try {
      final value = await _preferences.getString(_key(uid));
      if (value == null) return null;
      final draft = JajanDraft.fromJson(
        jsonDecode(value) as Map<String, dynamic>,
      );
      if (draft.id.isEmpty ||
          draft.id.contains('/') ||
          draft.capacity < 2 ||
          draft.capacity > 12 ||
          !['public', 'private'].contains(draft.joinPolicy) ||
          draft.description.runes.length > 150 ||
          draft.area.isFallback ||
          !draft.area.latitude.isFinite ||
          !draft.area.longitude.isFinite ||
          !draft.area.radius.isFinite ||
          draft.area.latitude.abs() > 85 ||
          draft.area.longitude.abs() > 180 ||
          draft.area.radius < 2000 ||
          draft.area.radius > 1000000) {
        throw const FormatException();
      }
      final saved = await _db
          .collection('jajan_events')
          .doc(draft.id)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 15));
      if (saved.exists) {
        await _preferences.remove(_key(uid));
        return null;
      }
      return draft;
    } catch (_) {
      throw const AuthFailure('jajanDraftError');
    }
  }

  Future<JajanDraft> prepare(
    String uid,
    Craving craving,
    int capacity,
    MapArea area, {
    String description = '',
    String joinPolicy = 'public',
  }) async {
    _requireUser(uid);
    if (area.isFallback ||
        !area.latitude.isFinite ||
        !area.longitude.isFinite ||
        !area.radius.isFinite ||
        area.latitude.abs() > 85 ||
        area.longitude.abs() > 180 ||
        area.radius < 2000 ||
        area.radius > 1000000) {
      throw const AuthFailure('jajanLocationRequired');
    }
    if (capacity < 2 || capacity > 12)
      throw const AuthFailure('jajanCapacityInvalid');
    if (!['public', 'private'].contains(joinPolicy))
      throw const AuthFailure('jajanSaveError');
    if (description.trim().runes.length > 150)
      throw const AuthFailure('descriptionTooLong');
    final draft = JajanDraft(
      id: _db.collection('jajan_events').doc().id,
      description: description.trim(),
      joinPolicy: joinPolicy,
      craving: craving,
      capacity: capacity,
      area: area,
    );
    // Persist before sending anything, so retries/restarts reuse the same document.
    try {
      await _preferences.setString(_key(uid), jsonEncode(draft.toJson()));
    } catch (_) {
      throw const AuthFailure('jajanDraftError');
    }
    return draft;
  }

  Future<JajanEvent> create(String uid, JajanDraft draft) async {
    // Retain the same saved ID through retries, including ambiguous commits.
    for (var attempt = 1; attempt <= 3; attempt++) {
      try {
        return await _createOnce(uid, draft);
      } catch (e) {
        final transient =
            e is TimeoutException ||
            (e is FirebaseException &&
                [
                  'unavailable',
                  'deadline-exceeded',
                  'aborted',
                ].contains(e.code)) ||
            (e is AuthFailure && e.message == 'jajanRetrySafe');
        if (kDebugMode)
          debugPrint(
            '[JajanCreate] attempt=$attempt error=${e is AuthFailure
                ? e.message
                : e is FirebaseException
                ? e.code
                : e.runtimeType}',
          );
        if (!transient || attempt == 3) rethrow;
        await Future<void>.delayed(Duration(milliseconds: 400 * attempt));
      }
    }
    throw const AuthFailure('jajanRetrySafe');
  }

  Future<JajanEvent> _createOnce(String uid, JajanDraft draft) async {
    _requireUser(uid);
    final reference = _db.collection('jajan_events').doc(draft.id);
    await ensureCanCreate(uid, retryId: draft.id);
    try {
      await _db
          .runTransaction((transaction) async {
            final existing = await transaction.get(reference);
            if (existing.exists) {
              if (existing.data()?['creatorId'] != uid)
                throw const AuthFailure('jajanSaveError');
              return;
            }
            final slotRef = slot(uid);
            final active = await transaction.get(slotRef);
            final previousId = active.data()?['eventId'] as String?;
            if (previousId != null && previousId.isNotEmpty) {
              final previous = decode(
                await transaction.get(
                  _db.collection('jajan_events').doc(previousId),
                ),
              );
              if (previous?.isActive ?? false)
                throw const AuthFailure('jajanAlreadyActive');
            }
            if (_legacyBlocked(active.data()))
              throw const AuthFailure('jajanAlreadyActive');
            final profile = await transaction.get(
              _db.collection('users').doc(uid),
            );
            final data = draft.toJson();
            transaction.set(slotRef, {
              'eventId': draft.id,
              'legacyEventIds': active.data()?['legacyEventIds'] ?? <String>[],
              'legacyUntil':
                  active.data()?['legacyUntil'] ??
                  Timestamp.fromMillisecondsSinceEpoch(0),
            });
            transaction.set(reference, {
              'creatorId': uid,
              'creatorName': profile.data()?['name'],
              'creatorAvatarId': profile.data()?['avatarId'],
              'visibility': 'public',
              'description': draft.description,
              'joinPolicy': draft.joinPolicy,
              'craving': draft.craving.name,
              'capacity': draft.capacity,
              'memberIds': [uid], 'memberCount': 1, 'state': 'OPEN',
              'area': {
                'latCell': data['latCell'],
                'lngCell': data['lngCell'],
                'radiusMeters': data['radiusMeters'],
              },
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
              // Expiry is computed from the trusted server-created timestamp.
              'durationMinutes': 45,
            });
          })
          .timeout(const Duration(seconds: 25));
      JajanEvent? event;
      // A successful commit can precede an up-to-date read. Retry confirmation
      // without asking the user to submit again or creating another document.
      for (var attempt = 0; attempt < 3; attempt++) {
        final snapshot = await reference
            .get(const GetOptions(source: Source.server))
            .timeout(const Duration(seconds: 10));
        if (!snapshot.metadata.hasPendingWrites) event = decode(snapshot);
        if (event != null) break;
        await Future<void>.delayed(const Duration(milliseconds: 350));
      }
      if (event == null) throw const AuthFailure('jajanRetrySafe');
      // Failure to clear a local draft must not turn a successful write into failure.
      try {
        await _preferences.remove(_key(uid));
      } catch (_) {}
      return event;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        await ensureCanCreate(uid, retryId: draft.id);
      }
      throw AuthFailure(switch (e.code) {
        'permission-denied' => 'jajanPermission',
        'unavailable' || 'deadline-exceeded' || 'aborted' => 'jajanRetrySafe',
        _ => 'jajanSaveError',
      });
    } on TimeoutException {
      throw const AuthFailure('jajanRetrySafe');
    }
  }

  Future<List<JajanEvent>> loadOwn(String uid) async {
    _requireUser(uid);
    try {
      final snapshot = await _db
          .collection('jajan_events')
          .where('creatorId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 15));
      return snapshot.docs
          .map(decode)
          .whereType<JajanEvent>()
          .where((e) => e.isActive)
          .toList();
    } catch (_) {
      throw const AuthFailure('jajanLoadError');
    }
  }

  /// Three bounded queries cover the surrounding 3 x 3 coarse cells.
  /// Discovery never runs on camera gestures or for the preview location.
  Future<List<JajanEvent>> loadNearby(String uid, MapArea area) async {
    _requireUser(uid);
    if (area.isFallback) return [];
    final lat = (area.latitude / .02).round();
    final lng = (area.longitude / .02).round();
    final longitudes = [
      -1,
      0,
      1,
    ].map((offset) => ((lng + offset + 9000) % 18000) - 9000).toList();
    final cutoff = Timestamp.fromDate(
      DateTime.now().toUtc().subtract(const Duration(minutes: 45)),
    );
    try {
      final results = await Future.wait([
        for (final row in [lat - 1, lat, lat + 1])
          if (row >= -4250 && row <= 4250)
            _db
                .collection('jajan_events')
                .where('visibility', isEqualTo: 'public')
                .where('state', isEqualTo: 'OPEN')
                .where('area.latCell', isEqualTo: row)
                .where('area.lngCell', whereIn: longitudes)
                .where('createdAt', isGreaterThan: cutoff)
                .orderBy('createdAt', descending: true)
                .limit(20)
                .get(const GetOptions(source: Source.server)),
      ]).timeout(const Duration(seconds: 15));
      return results
          .expand((s) => s.docs)
          .map(decode)
          .whereType<JajanEvent>()
          .where((e) => e.isActive)
          .toList();
    } catch (_) {
      throw const AuthFailure('jajanDiscoveryError');
    }
  }

  static JajanEvent? decode(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    if (data == null) return null;
    try {
      final area = data['area'] as Map<String, dynamic>;
      return JajanEvent(
        id: snapshot.id,
        joinPolicy: data['joinPolicy'] as String? ?? 'private',
        creatorId: data['creatorId'] as String,
        description: data['description'] as String? ?? '',
        creatorName: data['creatorName'] as String?,
        creatorAvatarId: data['creatorAvatarId'] as String?,
        memberIds: List<String>.from(data['memberIds'] as List? ?? const []),
        craving: Craving.values.byName(data['craving'] as String),
        capacity: data['capacity'] as int,
        memberCount: data['memberCount'] as int,
        state: data['state'] as String,
        createdAt: (data['createdAt'] as Timestamp).toDate().toUtc(),
        area: MapArea(
          (area['latCell'] as num).toDouble() * .02,
          (area['lngCell'] as num).toDouble() * .02,
          radius: (area['radiusMeters'] as num).toDouble(),
        ),
      );
    } catch (_) {
      return null;
    }
  }
}
