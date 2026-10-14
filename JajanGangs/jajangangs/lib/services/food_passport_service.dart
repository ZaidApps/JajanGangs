import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/food_memory.dart';
import '../models/auth_session.dart';

class FoodPassportService {
  final db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> entries(String uid) =>
      db.collection('users').doc(uid).collection('food_memories');
  Query<Map<String, dynamic>> query(String uid, bool mine) {
    Query<Map<String, dynamic>> q = entries(uid);
    if (!mine) q = q.where('visibility', isEqualTo: 'friends');
    return q.orderBy('createdAt', descending: true).limit(20);
  }

  Future<void> save(String uid, String id, Map<String, dynamic> data) async {
    if ((data['restaurant'] as String).trim().isEmpty ||
        (data['dish'] as String).trim().isEmpty ||
        (data['restaurant'] as String).runes.length > 80 ||
        (data['dish'] as String).runes.length > 80 ||
        (data['review'] as String).runes.length > 200 ||
        (data['area'] as String? ?? '').runes.length > 80 ||
        (data['rating'] as int) < 1 ||
        (data['rating'] as int) > 5) {
      throw const AuthFailure('passportInvalid');
    }
    final ref = entries(uid).doc(id);
    await db.runTransaction((tx) async {
      final old = await tx.get(ref);
      tx.set(ref, {
        ...data,
        'createdAt': old.data()?['createdAt'] ?? FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> delete(String uid, FoodMemory memory) =>
      db.runTransaction((tx) async {
        final ref = entries(uid).doc(memory.id);
        await tx.get(ref);
        tx.delete(ref);
      });

  Future<String?> destination(String eventId) async {
    final p = await db
        .collection('jajan_events')
        .doc(eventId)
        .collection('polls')
        .doc('current')
        .get()
        .timeout(const Duration(seconds: 10));
    final d = p.data();
    if (d == null || d['status'] != 'CLOSED') return null;
    final options = List<String>.from(d['options'] as List);
    final winner = d['winner'] as int;
    return winner >= 0 && winner < options.length ? options[winner] : null;
  }
}
