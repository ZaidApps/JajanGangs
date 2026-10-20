import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_session.dart';
import 'friends_service.dart';
import 'jajan_service.dart';
import 'social_safety_service.dart';

class EventSocialService {
  final db = FirebaseFirestore.instance;

  static const _inviteCachePrefix = 'jajan_sent_invite_v1/';
  String _cachePrefix(String id, String uid) => '$_inviteCachePrefix$uid/$id/';

  /// Local UI history only; authorization remains in the send transaction.
  Future<Set<String>> cachedInvites(String id, String uid) async {
    final sent = <String>{};
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefix = _cachePrefix(id, uid);
      final cutoff = DateTime.now()
          .subtract(const Duration(days: 8))
          .millisecondsSinceEpoch;
      for (final key in prefs.getKeys()) {
        if (!key.startsWith(_inviteCachePrefix)) continue;
        if ((prefs.getInt(key) ?? 0) < cutoff) {
          await prefs.remove(key);
        } else if (key.startsWith(prefix)) {
          sent.add(key.substring(prefix.length));
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[EventInviteCache] load failed: $e');
    }
    return sent;
  }

  Future<void> _rememberInvite(String id, String uid, String peer) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        '${_cachePrefix(id, uid)}$peer',
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      // A local storage failure must not turn a delivered invitation into
      // a reported send failure.
      if (kDebugMode) debugPrint('[EventInviteCache] save failed: $e');
    }
  }

  Future<void> invite(String id, String uid, String peer) async {
    final friends = FriendsService();
    friends.requireUser(uid);
    final ref = db.collection('jajan_events').doc(id);
    final notice = ref.collection('event_notifications').doc('invite_$peer');
    await db
        .runTransaction((tx) async {
          final event = JajanService.decode(await tx.get(ref));
          final relation = await tx.get(friends.relation(uid, peer));
          final old = await tx.get(notice);
          await SocialSafetyService().requireUnblocked(tx, uid, peer);
          if (event == null ||
              event.creatorId != uid ||
              !event.isActive ||
              event.state != 'OPEN') {
            throw const AuthFailure('eventClosed');
          }
          if (relation.data()?['status'] != 'ACCEPTED')
            throw const AuthFailure('friendChanged');
          if (event.memberIds.contains(peer))
            throw const AuthFailure('eventAlreadyMember');
          if (event.memberCount >= event.capacity)
            throw const AuthFailure('eventFull');
          if (old.exists) return;
          tx.set(notice, {
            'type': 'event_invite',
            'eventId': id,
            'recipientIds': [peer],
            'requesterName': event.creatorName ?? '',
            'versionId': peer,
            'createdAt': FieldValue.serverTimestamp(),
            'readBy': <String, dynamic>{},
          });
        })
        .timeout(const Duration(seconds: 25));
    await _rememberInvite(id, uid, peer);
  }

  Future<void> leave(String id, String uid) async {
    FriendsService().requireUser(uid);
    final ref = db.collection('jajan_events').doc(id);
    await db
        .runTransaction((tx) async {
          final event = JajanService.decode(await tx.get(ref));
          if (event == null) throw const AuthFailure('eventUnavailable');
          if (event.creatorId == uid) throw const AuthFailure('leaveHost');
          if (!event.memberIds.contains(uid)) return;
          if (!event.isActive) throw const AuthFailure('eventClosed');
          tx.update(ref, {
            'memberIds': event.memberIds.where((id) => id != uid).toList(),
            'memberCount': event.memberCount - 1,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          tx.delete(ref.collection('join_requests').doc(uid));
        })
        .timeout(const Duration(seconds: 25));
  }
}
