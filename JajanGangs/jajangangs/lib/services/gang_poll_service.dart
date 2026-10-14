import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/auth_session.dart';
import '../models/gang_poll.dart';
import 'jajan_service.dart';

class GangPollService {
  final db = FirebaseFirestore.instance;
  DocumentReference<Map<String, dynamic>> event(String id) =>
      db.collection('jajan_events').doc(id);
  DocumentReference<Map<String, dynamic>> poll(String id) =>
      event(id).collection('polls').doc('current');

  Future<void> create(String id, String uid, List<String> input) async {
    final options = input.map((s) => s.trim()).toList();
    if (options.length < 2 ||
        options.length > 5 ||
        options.any((s) => s.isEmpty || s.length > 60) ||
        options.map((s) => s.toLowerCase()).toSet().length != options.length) {
      throw const AuthFailure('pollInvalid');
    }
    await db
        .runTransaction((tx) async {
          final e = JajanService.decode(await tx.get(event(id)));
          final previous = await tx.get(poll(id));
          if (e == null || !e.memberIds.contains(uid) || !e.isActive)
            throw const AuthFailure('pollClosed');
          if (previous.exists) throw const AuthFailure('pollExists');
          if (e.state != 'OPEN') throw const AuthFailure('pollClosed');
          tx.set(poll(id), {
            'options': options,
            'status': 'OPEN',
            'winner': -1,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'lastVoter': '',
            'lastChoice': -1,
            for (var i = 0; i < 5; i++) 'v$i': <String>[],
          });
          tx.update(event(id), {
            'state': 'DECIDING',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        })
        .timeout(const Duration(seconds: 25));
  }

  Future<void> vote(String id, String uid, int choice) => db
      .runTransaction((tx) async {
        final e = JajanService.decode(await tx.get(event(id)));
        final doc = await tx.get(poll(id));
        if (e == null ||
            !e.isActive ||
            e.state != 'DECIDING' ||
            !e.memberIds.contains(uid) ||
            !doc.exists)
          throw const AuthFailure('pollClosed');
        final p = GangPoll(doc.data()!);
        if (p.closed || choice < 0 || choice >= p.options.length)
          throw const AuthFailure('pollClosed');
        if (p.choice(uid) == choice) return;
        tx.update(poll(id), {
          for (var i = 0; i < 5; i++)
            'v$i': [
              ...p.buckets[i].where((v) => v != uid),
              if (i == choice) uid,
            ],
          'lastVoter': uid,
          'lastChoice': choice,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      })
      .timeout(const Duration(seconds: 25));

  Future<void> finish(String id, String uid, int winner) => db
      .runTransaction((tx) async {
        final e = JajanService.decode(await tx.get(event(id)));
        final doc = await tx.get(poll(id));
        if (e == null || e.creatorId != uid || !doc.exists)
          throw const AuthFailure('pollClosed');
        final p = GangPoll(doc.data()!);
        if (p.closed && e.state == 'DESTINATION_SELECTED') return;
        if (!e.isActive || e.state != 'DECIDING' || p.closed)
          throw const AuthFailure('pollClosed');
        if (!p.leaders.contains(winner)) throw const AuthFailure('pollChanged');
        tx.update(poll(id), {
          'status': 'CLOSED',
          'winner': winner,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        tx.update(event(id), {
          'state': 'DESTINATION_SELECTED',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      })
      .timeout(const Duration(seconds: 25));
}
