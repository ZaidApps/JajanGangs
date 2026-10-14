import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/food_memory.dart';
import '../services/food_passport_service.dart';

class FoodPassportController extends ChangeNotifier {
  FoodPassportController(this.uid, this.mine);
  final String uid;
  final bool mine;
  final service = FoodPassportService();
  final List<FoodMemory> items = [];
  DocumentSnapshot<Map<String, dynamic>>? cursor;
  bool loading = false, more = true, disposed = false;
  String? error;
  Future<void> load({bool reset = false}) async {
    if (loading) return;
    loading = true;
    error = null;
    if (reset) {
      items.clear();
      cursor = null;
      more = true;
    }
    notifyListeners();
    try {
      var q = service.query(uid, mine);
      if (cursor != null) q = q.startAfterDocument(cursor!);
      final page = await q
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 15));
      if (disposed) return;
      for (final doc in page.docs) {
        items.removeWhere((e) => e.id == doc.id);
        items.add(FoodMemory(doc.id, doc.data()));
      }
      more = page.docs.length == 20;
      if (page.docs.isNotEmpty) cursor = page.docs.last;
    } catch (_) {
      if (!disposed) error = 'passportError';
    } finally {
      if (!disposed) {
        loading = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }
}
