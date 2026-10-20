import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/auth_session.dart';
import 'friends_service.dart';
import 'social_safety_service.dart';

class PermanentGangService {
  final db = FirebaseFirestore.instance;
  DocumentReference<Map<String, dynamic>> gang(String id) =>
      db.collection('gangs').doc(id);
  DocumentReference<Map<String, dynamic>> inviteRef(String id, String peer) =>
      gang(id).collection('event_notifications').doc(peer);
  Future<void> create(
    String id,
    String uid,
    String name,
    String avatar,
    int capacity,
  ) async {
    FriendsService().requireUser(uid);
    if (name.trim().isEmpty || name.trim().runes.length > 40)
      throw const AuthFailure('pgInvalid');
    await db.runTransaction((tx) async {
      final old = await tx.get(gang(id));
      final profile = (await tx.get(db.collection('users').doc(uid))).data()!;
      if (old.exists) return;
      tx.set(gang(id), {
        'name': name.trim(),
        'avatarId': avatar,
        'capacity': capacity,
        'ownerId': uid,
        'memberIds': [uid],
        'members': {
          uid: {'name': profile['name'], 'avatarId': profile['avatarId']},
        },
        'state': 'ACTIVE',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastId': '',
        'lastSenderId': '',
      });
    });
  }

  Future<void> invite(String id, String uid, String peer) async {
    FriendsService().requireUser(uid);
    final version = db.collection('gangs').doc().id;
    await db.runTransaction((tx) async {
      final g = (await tx.get(gang(id))).data();
      final old = await tx.get(inviteRef(id, peer));
      final f = await tx.get(FriendsService().relation(uid, peer));
      await SocialSafetyService().requireUnblocked(tx, uid, peer);
      if (g == null ||
          g['state'] != 'ACTIVE' ||
          !(g['memberIds'] as List).contains(uid))
        throw const AuthFailure('pgUnavailable');
      if ((g['memberIds'] as List).contains(peer))
        throw const AuthFailure('pgAlreadyMember');
      if ((g['memberIds'] as List).length >= g['capacity'])
        throw const AuthFailure('pgFull');
      if (f.data()?['status'] != 'ACCEPTED')
        throw const AuthFailure('pgFriendsOnly');
      if (old.data()?['status'] == 'REQUESTED') return;
      tx.set(inviteRef(id, peer), {
        'type': 'gang_invite',
        'gangId': id,
        'recipientIds': [peer],
        'inviterId': uid,
        'gangName': g['name'],
        'status': 'REQUESTED',
        'versionId': version,
        'createdAt': FieldValue.serverTimestamp(),
        'readBy': <String, dynamic>{},
      });
    });
  }

  Future<void> respond(String id, String uid, bool accept) async {
    FriendsService().requireUser(uid);
    await db.runTransaction((tx) async {
      final g = (await tx.get(gang(id))).data();
      final ref = inviteRef(id, uid);
      final invitation = (await tx.get(ref)).data();
      if (invitation == null || invitation['status'] != 'REQUESTED')
        throw const AuthFailure('pgUnavailable');
      if (accept) {
        if (g == null || g['state'] != 'ACTIVE')
          throw const AuthFailure('pgUnavailable');
        final inviter = invitation['inviterId'] as String;
        final f = await tx.get(FriendsService().relation(uid, inviter));
        await SocialSafetyService().requireUnblocked(tx, uid, inviter);
        final profile = (await tx.get(db.collection('users').doc(uid))).data()!;
        if (f.data()?['status'] != 'ACCEPTED' ||
            !(g['memberIds'] as List).contains(inviter))
          throw const AuthFailure('pgFriendsOnly');
        final ids = List<String>.from(g['memberIds']);
        if (!ids.contains(uid)) {
          if (ids.length >= g['capacity']) throw const AuthFailure('pgFull');
          ids.add(uid);
          tx.update(gang(id), {
            'memberIds': ids,
            'members': {
              ...Map<String, dynamic>.from(g['members']),
              uid: {'name': profile['name'], 'avatarId': profile['avatarId']},
            },
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
      tx.update(ref, {
        'status': accept ? 'ACCEPTED' : 'REJECTED',
        'readBy': {uid: invitation['versionId']},
      });
    });
  }

  Future<void> manage(
    String id,
    String uid, {
    String? name,
    int? capacity,
    String? newOwner,
    String? remove,
  }) async {
    FriendsService().requireUser(uid);
    await db.runTransaction((tx) async {
      final g = (await tx.get(gang(id))).data();
      if (g == null || g['state'] != 'ACTIVE')
        throw const AuthFailure('pgUnavailable');
      final ids = List<String>.from(g['memberIds']);
      final members = Map<String, dynamic>.from(g['members']);
      if (remove != null) {
        if (remove == g['ownerId']) throw const AuthFailure('pgTransferFirst');
        ids.remove(remove);
        members.remove(remove);
      }
      if (capacity != null && capacity < ids.length)
        throw const AuthFailure('pgCapacity');
      if (name != null &&
          (name.trim().isEmpty || name.trim().runes.length > 40))
        throw const AuthFailure('pgInvalid');
      tx.update(gang(id), {
        'memberIds': ids,
        'members': members,
        if (name != null) 'name': name.trim(),
        if (capacity != null) 'capacity': capacity,
        if (newOwner != null) 'ownerId': newOwner,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> send(
    String id,
    String uid,
    String messageId,
    String text,
  ) async {
    FriendsService().requireUser(uid);
    if (text.trim().isEmpty || text.trim().runes.length > 1000)
      throw const AuthFailure('pgInvalid');
    final ref = gang(id).collection('messages').doc(messageId);
    await db.runTransaction((tx) async {
      final g = (await tx.get(gang(id))).data();
      final old = await tx.get(ref);
      final p = (await tx.get(db.collection('users').doc(uid))).data()!;
      if (g == null ||
          g['state'] != 'ACTIVE' ||
          !(g['memberIds'] as List).contains(uid))
        throw const AuthFailure('pgUnavailable');
      if (old.exists) return;
      tx.set(ref, {
        'senderId': uid,
        'name': p['name'],
        'avatarId': p['avatarId'],
        'text': text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      tx.update(gang(id), {
        'lastId': messageId,
        'lastSenderId': uid,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      tx.set(gang(id).collection('event_notifications').doc('message'), {
        'type': 'gang_message',
        'gangId': id,
        'recipientIds': List<String>.from(g['memberIds'])
            .where((u) => u != uid)
            .toList(),
        'versionId': messageId,
        'createdAt': FieldValue.serverTimestamp(),
        'readBy': <String, dynamic>{},
      });
    });
  }

  Future<void> cursor(
    String id,
    String uid,
    String messageId, {
    bool hide = false,
  }) async {
    FriendsService().requireUser(uid);
    final ref = gang(id).collection('chat_state').doc(uid);
    final notice = gang(id).collection('event_notifications').doc('message');
    await db.runTransaction((tx) async {
      await tx.get(ref);
      final notification = hide ? null : await tx.get(notice);
      tx.set(ref, {
        hide ? 'hiddenId' : 'readId': messageId,
      }, SetOptions(merge: true));
      final d = notification?.data();
      if (d != null &&
          d['versionId'] == messageId &&
          (d['recipientIds'] as List).contains(uid)) {
        tx.update(notice, {
          'readBy': {...Map<String, dynamic>.from(d['readBy']), uid: messageId},
        });
      }
    });
  }

  Future<void> delete(String id, String uid) async {
    FriendsService().requireUser(uid);
    final exists = await db.runTransaction((tx) async {
      final old = await tx.get(gang(id));
      if (!old.exists) return false;
      if (old.data()!['ownerId'] != uid)
        throw const AuthFailure('pgUnavailable');
      tx.update(gang(id), {
        'state': 'DELETING',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    });
    if (!exists) return;
    for (final collection in [
      'messages',
      'event_notifications',
      'chat_state',
    ]) {
      while (true) {
        final page = await gang(id)
            .collection(collection)
            .limit(100)
            .get(const GetOptions(source: Source.server));
        if (page.docs.isEmpty) break;
        final batch = db.batch();
        for (final doc in page.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
    }
    await gang(id).delete();
  }
}
