import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PermanentGangInboxController extends ChangeNotifier {
  PermanentGangInboxController(this.uid);
  final String uid;
  final pages = <int, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};
  final subscriptions = <StreamSubscription>[];
  bool loading = true, failed = false, more = false, disposed = false;
  int generation = 0;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> get items {
    final all = {
      for (final page in pages.values)
        for (final doc in page) doc.id: doc,
    };
    return all.values.toList()..sort(
      (a, b) => (b.data()['createdAt'] as Timestamp? ?? Timestamp(0, 0))
          .compareTo(a.data()['createdAt'] as Timestamp? ?? Timestamp(0, 0)),
    );
  }

  void emit() {
    if (!disposed) notifyListeners();
  }

  void start() {
    generation++;
    for (final s in subscriptions) {
      s.cancel();
    }
    subscriptions.clear();
    pages.clear();
    load(0, null);
  }

  void older() {
    if (loading || !more) return;
    final page = pages[pages.length - 1];
    if (page != null && page.isNotEmpty) load(pages.length, page.last);
  }

  void load(int page, DocumentSnapshot<Map<String, dynamic>>? after) {
    loading = true;
    failed = false;
    final token = generation;
    emit();
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('gangs')
        .where('memberIds', arrayContains: uid)
        .orderBy('createdAt', descending: true);
    if (after != null) query = query.startAfterDocument(after);
    subscriptions.add(
      query
          .limit(20)
          .snapshots()
          .listen(
            (snapshot) {
              if (disposed || token != generation) return;
              pages[page] = snapshot.docs;
              loading = false;
              failed = false;
              if (page == pages.length - 1) more = snapshot.docs.length == 20;
              emit();
            },
            onError: (Object e) {
              if (disposed || token != generation) return;
              loading = false;
              failed = true;
              emit();
            },
          ),
    );
  }

  @override
  void dispose() {
    disposed = true;
    for (final s in subscriptions) {
      s.cancel();
    }
    super.dispose();
  }
}
