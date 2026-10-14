import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageDelivery { pending, sent, failed }

class GangMessage {
  GangMessage(DocumentSnapshot<Map<String, dynamic>> doc)
    : id = doc.id,
      senderId = doc.data()!['senderId'] as String,
      name = doc.data()!['name'] as String,
      avatarId = doc.data()!['avatarId'] as String,
      text = doc.data()!['text'] as String,
      timestamp = doc.data()!['createdAt'] as Timestamp?,
      createdAt = (doc.data()!['createdAt'] as Timestamp?)?.toDate(),
      delivery = doc.metadata.hasPendingWrites
          ? MessageDelivery.pending
          : MessageDelivery.sent;
  GangMessage.local({
    required this.id,
    required this.senderId,
    required this.name,
    required this.avatarId,
    required this.text,
    required this.createdAt,
    this.delivery = MessageDelivery.pending,
  }) : timestamp = null;
  final String id, senderId, name, avatarId, text;
  final DateTime? createdAt;
  final Timestamp? timestamp;
  MessageDelivery delivery;
}
