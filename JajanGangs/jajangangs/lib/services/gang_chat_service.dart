import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/auth_session.dart';
import '../models/gang_message.dart';
import 'jajan_service.dart';

class GangChatService {
  final db = FirebaseFirestore.instance;
  DocumentReference<Map<String, dynamic>> event(String id) =>
      db.collection('jajan_events').doc(id);
  Query<Map<String, dynamic>> messages(String id) =>
      event(id)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .orderBy(FieldPath.documentId, descending: true);
  String newId(String id) => event(id).collection('messages').doc().id;

  Future<void> markRead(String id, String uid, GangMessage message) async {
    final stamp = message.timestamp;
    if (stamp == null) return;
    final state = event(id).collection('chat_state').doc(uid);
    final notification = event(id)
        .collection('event_notifications')
        .doc('message');
    await db
        .runTransaction((tx) async {
          final previous = await tx.get(state);
          final notice = await tx.get(notification);
          final readAt = previous.data()?['readAt'] as Timestamp?;
          final readId = previous.data()?['readId'] as String? ?? '';
          if (readAt == null ||
              readAt.compareTo(stamp) < 0 ||
              (readAt == stamp && readId.compareTo(message.id) < 0)) {
            tx.set(state, {
              'readAt': stamp,
              'readId': message.id,
            }, SetOptions(merge: true));
          }
          final noticeAt = notice.data()?['createdAt'] as Timestamp?;
          if (noticeAt != null &&
              (notice.data()?['recipientIds'] as List? ?? []).contains(uid) &&
              (noticeAt.compareTo(stamp) < 0 ||
                  (noticeAt == stamp &&
                      (notice.data()?['versionId'] as String? ?? '').compareTo(
                            message.id,
                          ) <=
                          0))) {
            tx.update(notification, {
              'readBy': {
                ...Map<String, dynamic>.from(
                  notice.data()?['readBy'] as Map? ?? {},
                ),
                uid: notice.data()!['versionId'],
              },
            });
          }
        })
        .timeout(const Duration(seconds: 15));
  }

  Future<void> send(
    String eventId,
    String uid,
    String messageId,
    String text,
  ) async {
    if (text.trim().isEmpty || text.length > 1000)
      throw const AuthFailure('chatInvalid');
    await db
        .runTransaction((tx) async {
          final ref = event(eventId).collection('messages').doc(messageId);
          final parent = await tx.get(event(eventId));
          final e = JajanService.decode(parent);
          if (e == null || !e.memberIds.contains(uid) || !e.isActive)
            throw const AuthFailure('chatClosed');
          final existing = await tx.get(ref);
          if (existing.exists)
            return; // Same ID on retry prevents duplicate messages.
          final profile = await tx.get(db.collection('users').doc(uid));
          tx.set(ref, {
            'senderId': uid,
            'name': profile.data()?['name'],
            'avatarId': profile.data()?['avatarId'],
            'text': text.trim(),
            'createdAt': FieldValue.serverTimestamp(),
          });
          // Three fixed writes regardless of gang size. Rules require these
          // records to reference the new message in the same atomic commit.
          tx.set(event(eventId).collection('chat_summary').doc('latest'), {
            'lastMessageId': messageId,
            'lastMessageAt': FieldValue.serverTimestamp(),
            'lastSenderId': uid,
            'lastName': profile.data()?['name'],
            'lastText': text.trim(),
          });
          tx.set(
            event(eventId).collection('event_notifications').doc('message'),
            {
              'eventId': eventId,
              'type': 'message',
              'recipientIds': e.memberIds
                  .where((member) => member != uid)
                  .toList(),
              'createdAt': FieldValue.serverTimestamp(),
              'versionId': messageId,
              'readBy': <String, dynamic>{},
            },
          );
        })
        .timeout(const Duration(seconds: 25));
  }
}
