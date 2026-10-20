import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/auth_session.dart';
import 'friends_service.dart';

class SocialSafetyService {
  final db = FirebaseFirestore.instance;
  DocumentReference<Map<String, dynamic>> blockRef(String uid, String peer) =>
      db.collection('users').doc(uid).collection('blocks').doc(peer);

  Future<void> requireUnblocked(Transaction tx, String uid, String peer) async {
    final own = await tx.get(blockRef(uid, peer));
    final other = await tx.get(blockRef(peer, uid));
    if (own.exists || other.exists) throw const AuthFailure('socialBlocked');
  }

  Future<void> block(String uid, String peer, String name) async {
    final friends = FriendsService();
    friends.requireUser(uid);
    if (uid == peer) throw const AuthFailure('socialFailed');
    await db
        .runTransaction((tx) async {
          final old = await tx.get(blockRef(uid, peer));
          final relation = await tx.get(friends.relation(uid, peer));
          if (old.exists) return;
          tx.set(blockRef(uid, peer), {
            'name': name,
            'createdAt': FieldValue.serverTimestamp(),
          });
          if (relation.exists) {
            final data = relation.data()!;
            tx.delete(friends.relation(uid, peer));
            tx.delete(friends.relation(peer, uid));
            if (data['status'] == 'REQUESTED') {
              tx.delete(
                friends.notice(
                  data['toId'] as String,
                  data['fromId'] as String,
                ),
              );
            }
          }
        })
        .timeout(const Duration(seconds: 25));
  }

  Future<void> unblock(String uid, String peer) async {
    FriendsService().requireUser(uid);
    await blockRef(uid, peer).delete().timeout(const Duration(seconds: 20));
  }

  Future<void> report(
    String uid,
    String peer,
    String reason,
    String details,
    String reportId, {
    String? eventId,
  }) async {
    FriendsService().requireUser(uid);
    if (uid == peer ||
        !['spam', 'harassment', 'unsafe', 'other'].contains(reason) ||
        details.trim().runes.length > 500) {
      throw const AuthFailure('socialFailed');
    }
    // Stable ID for a retry after a network timeout. Reports cannot be edited.
    final ref = db.collection('user_reports').doc(reportId);
    await db
        .runTransaction((tx) async {
          if ((await tx.get(ref)).exists) return;
          tx.set(ref, {
            'reporterId': uid,
            'targetId': peer,
            'reason': reason,
            'details': details.trim(),
            'eventId': eventId ?? '',
            'createdAt': FieldValue.serverTimestamp(),
            'status': 'NEW',
          });
        })
        .timeout(const Duration(seconds: 25));
  }
}
