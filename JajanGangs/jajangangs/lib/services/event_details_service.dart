import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/auth_session.dart';
import '../models/jajan_event.dart';
import 'jajan_service.dart';

class EventDetailsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  DocumentReference<Map<String, dynamic>> eventRef(String id) =>
      _db.collection('jajan_events').doc(id);
  CollectionReference<Map<String, dynamic>> requests(String id) =>
      eventRef(id).collection('join_requests');

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchEvent(String id) =>
      eventRef(id).snapshots(includeMetadataChanges: true);
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchRequest(
    String id,
    String uid,
  ) => requests(id).doc(uid).snapshots(includeMetadataChanges: true);

  Future<int> pendingCount(String id) async =>
      (await requests(id)
              .where('status', whereIn: ['REQUESTED', 'PENDING'])
              .count()
              .get()
              .timeout(const Duration(seconds: 15)))
          .count ??
      0;

  Future<QuerySnapshot<Map<String, dynamic>>> pendingPage(
    String id,
    DocumentSnapshot<Map<String, dynamic>>? after,
  ) {
    Query<Map<String, dynamic>> query = requests(id)
        .where('status', whereIn: ['REQUESTED', 'PENDING'])
        .orderBy('createdAt');
    if (after != null) query = query.startAfterDocument(after);
    return query
        .limit(20)
        .get(const GetOptions(source: Source.server))
        .timeout(const Duration(seconds: 15));
  }

  Future<void> decide(
    String id,
    String uid,
    String requester, {
    required bool accept,
  }) async {
    if (FirebaseAuth.instance.currentUser?.uid != uid)
      throw const AuthFailure('signInAgain');
    await _db
        .runTransaction((tx) async {
          final eventDoc = await tx.get(eventRef(id));
          final requestRef = requests(id).doc(requester);
          final request = await tx.get(requestRef);
          final event = JajanService.decode(eventDoc);
          if (event == null ||
              event.creatorId != uid ||
              !event.isActive ||
              event.state != 'OPEN') {
            throw const AuthFailure('eventClosed');
          }
          final target = accept ? 'ACCEPTED' : 'REJECTED';
          if (request.data()?['status'] == target) return;
          if (!['REQUESTED', 'PENDING'].contains(request.data()?['status'])) {
            throw const AuthFailure('requestAlreadyDecided');
          }
          if (accept) {
            if (event.memberCount >= event.capacity)
              throw const AuthFailure('eventFull');
            if (event.memberIds.contains(requester))
              throw const AuthFailure('eventAlreadyMember');
            tx.update(eventRef(id), {
              'memberIds': [...event.memberIds, requester],
              'memberCount': event.memberCount + 1,
              'lastAcceptedUid': requester,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
          tx.update(requestRef, {
            'status': target,
            'decidedAt': FieldValue.serverTimestamp(),
          });
          tx.set(
            eventRef(id)
                .collection('event_notifications')
                .doc('${requester}_decision'),
            {
              'eventId': id,
              'type': accept ? 'accepted' : 'rejected',
              'recipientIds': [requester],
              'createdAt': FieldValue.serverTimestamp(),
              'versionId': target,
              'readBy': <String, dynamic>{},
            },
          );
        })
        .timeout(const Duration(seconds: 25));
  }

  Future<String> join(String id, String uid) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.uid != uid || !user.emailVerified) {
      throw const AuthFailure('signInAgain');
    }
    // UID as document ID makes retries safe even after an ambiguous timeout.
    return await _db
        .runTransaction<String>((transaction) async {
          final request = requests(id).doc(uid);
          final previous = await transaction.get(request);
          if (previous.exists)
            return previous.data()?['status'] as String? ?? 'REQUESTED';
          final snapshot = await transaction.get(eventRef(id));
          final JajanEvent? event = JajanService.decode(snapshot);
          if (event == null || !event.isActive || event.state != 'OPEN')
            throw const AuthFailure('eventExpired');
          if (event.creatorId == uid || event.memberIds.contains(uid)) {
            throw const AuthFailure('eventAlreadyMember');
          }
          if (event.memberCount >= event.capacity)
            throw const AuthFailure('eventFull');
          final profile = await transaction.get(
            _db.collection('users').doc(uid),
          );
          transaction.set(request, {
            'userId': uid,
            'name': profile.data()?['name'],
            'avatarId': profile.data()?['avatarId'],
            'status': event.isPublic ? 'ACCEPTED' : 'REQUESTED',
            'createdAt': FieldValue.serverTimestamp(),
          });
          if (event.isPublic) {
            transaction.update(eventRef(id), {
              'memberIds': [...event.memberIds, uid],
              'memberCount': event.memberCount + 1,
              'lastAcceptedUid': uid,
              'updatedAt': FieldValue.serverTimestamp(),
            });
            transaction.set(
              eventRef(id)
                  .collection('event_notifications')
                  .doc('${uid}_joined'),
              {
                'eventId': id,
                'type': 'member_joined',
                'recipientIds': [event.creatorId],
                'createdAt': FieldValue.serverTimestamp(),
                'versionId': uid,
                'readBy': <String, dynamic>{},
                'requesterName': profile.data()?['name'],
              },
            );
            return 'ACCEPTED';
          }
          transaction.set(
            eventRef(id)
                .collection('event_notifications')
                .doc('${uid}_request'),
            {
              'eventId': id,
              'type': 'join_request',
              'recipientIds': [event.creatorId],
              'createdAt': FieldValue.serverTimestamp(),
              'versionId': uid,
              'readBy': <String, dynamic>{},
              'requesterName': profile.data()?['name'],
            },
          );
          return 'REQUESTED';
        })
        .timeout(const Duration(seconds: 25));
  }
}
