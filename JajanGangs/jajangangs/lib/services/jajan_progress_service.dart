import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/auth_session.dart';
import 'jajan_service.dart';

class JajanProgressService {
  Future<void> advance(String id, String uid, String target) async {
    if (!['ON_THE_WAY', 'COMPLETED'].contains(target))
      throw const AuthFailure('eventStatusChanged');
    final db = FirebaseFirestore.instance;
    final ref = db.collection('jajan_events').doc(id);
    await db
        .runTransaction((tx) async {
          final event = JajanService.decode(await tx.get(ref));
          if (event == null || event.creatorId != uid)
            throw const AuthFailure('eventStatusChanged');
          if (event.state == target) return;
          final expected = target == 'ON_THE_WAY'
              ? 'DESTINATION_SELECTED'
              : 'ON_THE_WAY';
          if (event.state != expected || !event.isActive)
            throw const AuthFailure('eventStatusChanged');
          tx.update(ref, {
            'state': target,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        })
        .timeout(const Duration(seconds: 25));
  }
}
