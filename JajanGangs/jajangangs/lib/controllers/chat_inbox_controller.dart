import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ChatInboxController extends ChangeNotifier {
  ChatInboxController(this.uid);
  final String uid;
  final rooms = <String, DocumentSnapshot<Map<String, dynamic>>>{};
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  DocumentSnapshot<Map<String, dynamic>>? _cursor;
  bool loading = true,
      more = true,
      paging = false,
      failed = false,
      _disposed = false;
  Query<Map<String, dynamic>> get _query => FirebaseFirestore.instance
      .collection('jajan_events')
      .where('memberIds', arrayContains: uid)
      .orderBy('createdAt', descending: true);
  void _emit() {
    if (!_disposed) notifyListeners();
  }

  void listen() {
    _subscription?.cancel();
    failed = false;
    _emit();
    _subscription = _query
        .limit(20)
        .snapshots(includeMetadataChanges: true)
        .listen(
          (page) {
            if (_disposed) return;
            for (final doc in page.docs) {
              rooms[doc.id] = doc;
            }
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
        rooms[doc.id] = doc;
      }
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
    if (rooms.remove(id) != null) _emit();
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}
