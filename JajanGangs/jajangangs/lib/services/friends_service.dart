import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/auth_session.dart';
import 'social_safety_service.dart';

class FriendsService {
  final db = FirebaseFirestore.instance;
  DocumentReference<Map<String, dynamic>> relation(String uid, String peer) =>
      db.collection('users').doc(uid).collection('friends').doc(peer);
  DocumentReference<Map<String, dynamic>> notice(String to, String from) => db
      .collection('users')
      .doc(to)
      .collection('event_notifications')
      .doc('friend_$from');
  void requireUser(String uid) {
    if (FirebaseAuth.instance.currentUser?.uid != uid ||
        FirebaseAuth.instance.currentUser?.emailVerified != true)
      throw const AuthFailure('signInAgain');
  }

  Query<Map<String, dynamic>> query(String uid, String kind) {
    var q = db
        .collection('users')
        .doc(uid)
        .collection('friends')
        .where(
          'status',
          isEqualTo: kind == 'friends' ? 'ACCEPTED' : 'REQUESTED',
        );
    if (kind != 'friends')
      q = q.where(kind == 'incoming' ? 'toId' : 'fromId', isEqualTo: uid);
    return q.orderBy('createdAt', descending: true);
  }

  Future<void> send(String uid, String peer, String eventId) async {
    requireUser(uid);
    if (uid == peer) throw const AuthFailure('friendUnavailable');
    final version = db.collection('users').doc().id;
    await db
        .runTransaction((tx) async {
          await SocialSafetyService().requireUnblocked(tx, uid, peer);
          final existing = await tx.get(relation(uid, peer));
          if (['REQUESTED', 'ACCEPTED'].contains(existing.data()?['status']))
            return;
          final event = await tx.get(
            db.collection('jajan_events').doc(eventId),
          );
          final e = event.data();
          if (e == null ||
              e['state'] == 'CANCELLING' ||
              !(e['memberIds'] as List).contains(peer))
            throw const AuthFailure('friendUnavailable');
          String? name, avatar;
          if (e['creatorId'] == peer) {
            name = e['creatorName'] as String?;
            avatar = e['creatorAvatarId'] as String?;
          } else {
            final member = await tx.get(
              event.reference.collection('join_requests').doc(peer),
            );
            if (member.data()?['status'] != 'ACCEPTED')
              throw const AuthFailure('friendUnavailable');
            name = member.data()?['name'] as String?;
            avatar = member.data()?['avatarId'] as String?;
          }
          final profile = await tx.get(db.collection('users').doc(uid));
          if (name == null || avatar == null || !profile.exists)
            throw const AuthFailure('friendUnavailable');
          final data = <String, dynamic>{
            'fromId': uid,
            'toId': peer,
            'fromName': profile.data()!['name'],
            'fromAvatarId': profile.data()!['avatarId'],
            'toName': name,
            'toAvatarId': avatar,
            'sourceEventId': eventId,
            'status': 'REQUESTED',
            'versionId': version,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          };
          tx.set(relation(uid, peer), data);
          tx.set(relation(peer, uid), data);
          tx.set(notice(peer, uid), {
            'type': 'friend_request',
            'friendUid': uid,
            'actorName': profile.data()!['name'],
            'recipientIds': [peer],
            'versionId': version,
            'createdAt': FieldValue.serverTimestamp(),
            'readBy': <String, dynamic>{},
          });
        })
        .timeout(const Duration(seconds: 25));
  }

  Future<void> change(String uid, String peer, String target) async {
    requireUser(uid);
    await db
        .runTransaction((tx) async {
          if (target == 'ACCEPTED')
            await SocialSafetyService().requireUnblocked(tx, uid, peer);
          final current = await tx.get(relation(uid, peer));
          final d = current.data();
          if (d == null) throw const AuthFailure('friendUnavailable');
          if (d['status'] == target) return;
          final requested = d['status'] == 'REQUESTED';
          final allowed =
              (requested &&
                  d['toId'] == uid &&
                  ['ACCEPTED', 'DECLINED'].contains(target)) ||
              (requested && d['fromId'] == uid && target == 'CANCELLED') ||
              (d['status'] == 'ACCEPTED' && target == 'REMOVED');
          if (!allowed) throw const AuthFailure('friendChanged');
          final changes = <String, dynamic>{
            'status': target,
            'updatedAt': FieldValue.serverTimestamp(),
          };
          if (target == 'ACCEPTED') {
            final profile = await tx.get(db.collection('users').doc(uid));
            if (!profile.exists) throw const AuthFailure('friendUnavailable');
            changes.addAll({
              'toName': profile.data()!['name'],
              'toAvatarId': profile.data()!['avatarId'],
            });
          }
          tx.update(relation(uid, peer), changes);
          tx.update(relation(peer, uid), changes);
          if (requested)
            tx.delete(notice(d['toId'] as String, d['fromId'] as String));
        })
        .timeout(const Duration(seconds: 25));
  }
}
