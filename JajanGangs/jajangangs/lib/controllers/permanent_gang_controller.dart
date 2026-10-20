import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/permanent_gang_service.dart';
import '../models/auth_session.dart';

class PermanentGangController extends ChangeNotifier {
  PermanentGangController(this.id, this.uid);
  final String id, uid;
  final service = PermanentGangService();
  Map<String, dynamic>? data;
  final messages = <String, Map<String, dynamic>>{};
  final pending = <String, Map<String, dynamic>>{};
  StreamSubscription? root, feed;
  int generation = 0;
  bool loading = true,
      failed = false,
      disposed = false,
      paging = false,
      more = true;
  DocumentSnapshot<Map<String, dynamic>>? cursor;
  bool get allowed =>
      data?['state'] == 'ACTIVE' &&
      (data?['memberIds'] as List? ?? []).contains(uid);
  void emit() {
    if (!disposed) notifyListeners();
  }

  void start() {
    final token = ++generation;
    root?.cancel();
    feed?.cancel();
    feed = null;
    messages.clear();
    cursor = null;
    more = true;
    loading = true;
    failed = false;
    root = service
        .gang(id)
        .snapshots(includeMetadataChanges: true)
        .listen(
          (doc) {
            if (disposed || token != generation) return;
            data = doc.data();
            loading = false;
            failed = false;
            if (!allowed) {
              feed?.cancel();
              feed = null;
              messages.clear();
              pending.clear();
            } else if (feed == null) {
              feed = query
                  .limit(50)
                  .snapshots(includeMetadataChanges: true)
                  .listen(
                    (page) {
                      if (disposed || token != generation) return;
                      for (final m in page.docs) {
                        messages[m.id] = {
                          ...m.data(),
                          'sending': m.metadata.hasPendingWrites,
                        };
                        if (!m.metadata.hasPendingWrites) pending.remove(m.id);
                      }
                      if (cursor == null && !page.metadata.isFromCache) {
                        cursor = page.docs.lastOrNull;
                        more = page.docs.length == 50;
                      }
                      emit();
                    },
                    onError: (Object e) {
                      if (disposed || token != generation) return;
                      failed = true;
                      emit();
                    },
                  );
            }
            emit();
          },
          onError: (Object e) {
            if (disposed || token != generation) return;
            loading = false;
            failed = true;
            data = null;
            messages.clear();
            feed?.cancel();
            feed = null;
            emit();
          },
        );
  }

  Query<Map<String, dynamic>> get query => service
      .gang(id)
      .collection('messages')
      .orderBy('createdAt', descending: true)
      .orderBy(FieldPath.documentId, descending: true);
  Future<void> older() async {
    if (paging || !more || cursor == null || !allowed) return;
    paging = true;
    emit();
    try {
      final page = await query.startAfterDocument(cursor!).limit(50).get();
      if (disposed || !allowed) return;
      for (final m in page.docs) {
        messages[m.id] = m.data();
      }
      if (page.docs.isNotEmpty) cursor = page.docs.last;
      more = page.docs.length == 50;
    } catch (_) {
      failed = true;
    } finally {
      paging = false;
      emit();
    }
  }

  Future<void> send(String text, {String? retryId}) async {
    if (!allowed || text.trim().isEmpty) return;
    final mid = retryId ?? service.gang(id).collection('messages').doc().id;
    pending[mid] = {
      'text': text.trim(),
      'senderId': uid,
      'name': (data?['members'] as Map?)?[uid]?['name'],
      'avatarId': (data?['members'] as Map?)?[uid]?['avatarId'],
      'createdAt': Timestamp.now(),
      'sending': true,
    };
    emit();
    try {
      await service.send(id, uid, mid, text);
      if (!disposed && pending.containsKey(mid))
        pending[mid] = {...pending[mid]!, 'sending': false};
    } catch (e) {
      if (!disposed && pending.containsKey(mid) && !messages.containsKey(mid))
        pending[mid] = {
          ...pending[mid]!,
          'sending': false,
          'error': e is AuthFailure ? e.message : 'pgError',
        };
    }
    emit();
  }

  @override
  void dispose() {
    disposed = true;
    root?.cancel();
    feed?.cancel();
    super.dispose();
  }
}
