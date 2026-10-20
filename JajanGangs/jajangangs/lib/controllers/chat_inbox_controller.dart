import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../services/jajan_service.dart';

class ChatInboxController extends ChangeNotifier {
  ChatInboxController(this.uid);
  final String uid;
  final rooms = <String, DocumentSnapshot<Map<String, dynamic>>>{};
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  DocumentSnapshot<Map<String, dynamic>>? _cursor;
  Timer? _expiryTimer;
  DateTime _cutoff = DateTime.now().subtract(
    const Duration(days: 7, minutes: 45),
  );
  bool loading = true,
      more = true,
      paging = false,
      failed = false,
      _disposed = false;
  Query<Map<String, dynamic>> get _query => FirebaseFirestore.instance
      .collection('jajan_events')
      .where('memberIds', arrayContains: uid)
      .where('createdAt', isGreaterThan: Timestamp.fromDate(_cutoff))
      .orderBy('createdAt', descending: true);
  void _emit() {
    if (!_disposed) notifyListeners();
  }

  void listen() {
    _subscription?.cancel();
    _cutoff = DateTime.now().subtract(const Duration(days: 7, minutes: 45));
    _cursor = null;
    _pruneExpired();
    failed = false;
    _emit();
    _subscription = _query
        .limit(20)
        .snapshots(includeMetadataChanges: true)
        .listen(
          (page) {
            if (_disposed) return;
            for (final doc in page.docs) {
              _remember(doc);
            }
            for (final change in page.docChanges) {
              if (change.type == DocumentChangeType.removed) {
                rooms.remove(change.doc.id);
              }
            }
            _pruneExpired();
            if (_cursor == null && !page.metadata.isFromCache) {
              _cursor = page.docs.lastOrNull;
              more = page.docs.length == 20;
            }
            loading = false;
            failed = false;
            _emit();
          },
          onError: (Object _) {
            loading = false;
            failed = true;
            _emit();
          },
        );
  }

  Future<void> older() async {
    if (paging || !more || _cursor == null) return;
    paging = true;
    failed = false;
    _emit();
    try {
      final page = await _query
          .startAfterDocument(_cursor!)
          .limit(20)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 15));
      if (_disposed) return;
      for (final doc in page.docs) {
        _remember(doc);
      }
      _pruneExpired();
      if (page.docs.isNotEmpty) _cursor = page.docs.last;
      more = page.docs.length == 20;
    } catch (_) {
      failed = true;
    } finally {
      paging = false;
      _emit();
    }
  }

  void remove(String id) {
    if (rooms.remove(id) != null) {
      _pruneExpired();
      _emit();
    }
  }

  void _remember(DocumentSnapshot<Map<String, dynamic>> doc) {
    final event = JajanService.decode(doc);
    if (event?.isActive == true && event!.memberIds.contains(uid)) {
      rooms[doc.id] = doc;
    } else {
      rooms.remove(doc.id);
    }
  }

  // One local timer for the next expiry; no polling or extra Firestore reads.
  void _pruneExpired() {
    _expiryTimer?.cancel();
    DateTime? next;
    rooms.removeWhere((id, doc) {
      final event = JajanService.decode(doc);
      if (event == null || !event.isActive || !event.memberIds.contains(uid)) {
        return true;
      }
      if (next == null || event.expiresAt.isBefore(next!))
        next = event.expiresAt;
      return false;
    });
    if (next != null && !_disposed) {
      final delay = next!.difference(DateTime.now()).inMilliseconds;
      _expiryTimer = Timer(
        Duration(milliseconds: delay > 0 ? delay + 10 : 10),
        () {
          if (_disposed) return;
          _pruneExpired();
          _emit();
        },
      );
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _expiryTimer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }
}
