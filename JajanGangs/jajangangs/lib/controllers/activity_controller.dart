import '../services/notification_sound.dart';

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ActivityController extends ChangeNotifier {
  ActivityController(this.uid);
  final String uid;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> items = [];
  bool loading = true, failed = false, _disposed = false;
  StreamSubscription? _subscription;
  bool _soundBaseline = false;
  final Set<String> _heard = {};
  void start() {
    _soundBaseline = false;
    _heard.clear();
    final sound = NotificationSound.instance;
    _subscription?.cancel();
    loading = true;
    failed = false;
    _subscription = FirebaseFirestore.instance
        .collectionGroup('event_notifications')
        .where('recipientIds', arrayContains: uid)
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots(includeMetadataChanges: true)
        .listen(
          (page) {
            if (_disposed) return;
            if (!page.metadata.isFromCache && !page.metadata.hasPendingWrites) {
              var chime = false;
              for (final doc in page.docs) {
                final data = doc.data();
                final key = '${doc.reference.path}:${data['versionId']}';
                final stamp = data['createdAt'] as Timestamp?;
                final fresh = _heard.add(key);
                if (_soundBaseline &&
                    fresh &&
                    !isRead(doc) &&
                    stamp != null &&
                    stamp.toDate().isAfter(sound.foregroundSince) &&
                    !(data['type'] == 'message' &&
                        data['eventId'] == sound.activeChat))
                  chime = true;
              }
              _soundBaseline = true;
              while (_heard.length > 200) {
                _heard.remove(_heard.first);
              }
              if (chime) unawaited(sound.play());
            }
            items = page.docs;
            loading = false;
            failed = false;
            notifyListeners();
          },
          onError: (Object error) {
            if (_disposed) return;
            failed = true;
            loading = false;
            notifyListeners();
            if (kDebugMode) debugPrint('[GangActivity] $error');
          },
        );
    if (!_disposed) notifyListeners();
  }

  bool isRead(DocumentSnapshot<Map<String, dynamic>> doc) =>
      (doc.data()?['readBy'] as Map? ?? {})[uid] == doc.data()?['versionId'];
  int get unread => items.where((doc) => !isRead(doc)).length;
  Future<void> read(DocumentSnapshot<Map<String, dynamic>> doc) =>
      FirebaseFirestore.instance
          .runTransaction((tx) async {
            final latest = await tx.get(doc.reference);
            if (!latest.exists ||
                latest.data()?['versionId'] != doc.data()?['versionId'])
              return;
            tx.update(doc.reference, {
              'readBy': {
                ...Map<String, dynamic>.from(
                  latest.data()?['readBy'] as Map? ?? {},
                ),
                uid: latest.data()!['versionId'],
              },
            });
          })
          .timeout(const Duration(seconds: 15));
  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}
