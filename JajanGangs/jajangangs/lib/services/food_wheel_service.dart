import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/auth_session.dart';
import '../models/food_wheel.dart';

class FoodWheelService {
  final db = FirebaseFirestore.instance;
  DocumentReference<Map<String, dynamic>> event(String id) =>
      db.collection('jajan_events').doc(id);
  DocumentReference<Map<String, dynamic>> current(String id) =>
      event(id).collection('wheels').doc('current');
  void requireActive(Map<String, dynamic>? e, String uid) {
    if (e == null ||
        !(e['memberIds'] as List).contains(uid) ||
        ![
          'OPEN',
          'DECIDING',
          'DESTINATION_SELECTED',
          'ON_THE_WAY',
        ].contains(e['state']) ||
        !((e['scheduledAt'] ?? e['createdAt']) as Timestamp)
            .toDate()
            .add(const Duration(minutes: 45))
            .isAfter(DateTime.now())) {
      throw const AuthFailure('wheelChanged');
    }
  }

  Future<void> create(String id, String uid) async {
    final round = event(id).collection('wheel_history').doc().id;
    await db.runTransaction((tx) async {
      final e = await tx.get(event(id));
      final old = await tx.get(current(id));
      final profile = await tx.get(db.collection('users').doc(uid));
      requireActive(e.data(), uid);
      if (old.exists && old.data()!['status'] != 'CLOSED')
        throw const AuthFailure('wheelChanged');
      if (old.exists)
        tx.set(
          event(id)
              .collection('wheel_history')
              .doc(old.data()!['roundId'] as String),
          old.data()!,
        );
      tx.set(current(id), {
        'roundId': round,
        'creatorId': uid,
        'creatorName': profile.data()!['name'],
        'status': 'OPEN',
        'choices': <String, dynamic>{},
        'winnerUid': '',
        'spunAt': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> contribute(
    String id,
    String uid,
    String round,
    String food,
  ) async {
    food = food.trim();
    if (food.isEmpty || food.runes.length > 40)
      throw const AuthFailure('wheelInvalid');
    await db.runTransaction((tx) async {
      final e = await tx.get(event(id));
      final snap = await tx.get(current(id));
      final profile = await tx.get(db.collection('users').doc(uid));
      requireActive(e.data(), uid);
      final data = snap.data();
      if (data == null || data['roundId'] != round || data['status'] != 'OPEN')
        throw const AuthFailure('wheelChanged');
      final choices = Map<String, dynamic>.from(data['choices'] as Map);
      if (choices.containsKey(uid)) throw const AuthFailure('wheelLocked');
      choices[uid] = {
        'food': food,
        'name': profile.data()!['name'],
        'avatarId': profile.data()!['avatarId'],
      };
      tx.update(current(id), {
        'choices': choices,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> spin(String id, String uid, String round) async {
    // Reused on transaction retries; the committed participant set determines the result.
    final random = Random.secure().nextDouble();
    await db.runTransaction((tx) async {
      final e = await tx.get(event(id));
      final snap = await tx.get(current(id));
      requireActive(e.data(), uid);
      if (!snap.exists) throw const AuthFailure('wheelChanged');
      final wheel = FoodWheel(snap.data()!);
      if (wheel.round != round ||
          (wheel.creator != uid &&
              !(e.data()!['creatorId'] == uid &&
                  !(e.data()!['memberIds'] as List).contains(wheel.creator))))
        throw const AuthFailure('wheelChanged');
      if (wheel.closed) return; // Safe retry: never reroll a committed result.
      final uids = wheel.uids;
      if (uids.length < 2) throw const AuthFailure('wheelMinimum');
      tx.update(current(id), {
        'status': 'CLOSED',
        'winnerUid': uids[(random * uids.length).floor()],
        'spunAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
