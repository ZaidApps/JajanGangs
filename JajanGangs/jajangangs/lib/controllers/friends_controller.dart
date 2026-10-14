import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/friendship.dart';
import '../services/friends_service.dart';

class FriendsController extends ChangeNotifier {
  FriendsController(this.uid, this.kind);
  final String uid, kind;
  final service = FriendsService();
  final _pages = <int, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};
  final _subscriptions = <StreamSubscription>[];
  bool loading = true, failed = false, more = false, _disposed = false;
  int _generation = 0;
  int? _pendingPage;
  final _errors = <int>{};
  Timer? _timer;
  List<Friendship> get items {
    final docs = {
      for (final page in _pages.values)
        for (final doc in page) doc.id: doc,
    };
    final sorted = docs.values.toList()
      ..sort(
        (a, b) => (b.data()['createdAt'] as Timestamp? ?? Timestamp(0, 0))
            .compareTo(a.data()['createdAt'] as Timestamp? ?? Timestamp(0, 0)),
      );
    return sorted.map(Friendship.new).toList();
  }

  void start() {
    _generation++;
    for (final s in _subscriptions) {
      s.cancel();
    }
    _subscriptions.clear();
    _pages.clear();
    _errors.clear();
    more = false;
    _listen(0, null);
  }

  void older() {
    if (loading || failed || !more || _pages.isEmpty) return;
    final last = _pages[_pages.length - 1];
    if (last == null || last.isEmpty) return;
    _listen(_pages.length, last.last);
  }

  void _listen(int page, DocumentSnapshot<Map<String, dynamic>>? after) {
    loading = true;
    _pendingPage = page;
    failed = false;
    final generation = _generation;
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 15), () {
      if (_disposed || generation != _generation || !loading) return;
      loading = false;
      _errors.add(page);
      failed = true;
      notifyListeners();
    });
    var q = service.query(uid, kind);
    if (after != null) q = q.startAfterDocument(after);
    _subscriptions.add(
      q
          .limit(20)
          .snapshots()
          .listen(
            (snapshot) {
              if (_disposed || generation != _generation) return;
              _pages[page] = snapshot.docs;
              if (page == _pages.length - 1) more = snapshot.docs.length == 20;
              _errors.remove(page);
              failed = _errors.isNotEmpty;
              if (_pendingPage == page) {
                loading = false;
                _pendingPage = null;
                _timer?.cancel();
              }
              notifyListeners();
            },
            onError: (Object e) {
              if (_disposed || generation != _generation) return;
              if (_pendingPage == page) {
                loading = false;
                _pendingPage = null;
                _timer?.cancel();
              }
              _errors.add(page);
              failed = true;
              if (kDebugMode) debugPrint('[FriendsList] $e');
              notifyListeners();
            },
          ),
    );
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    for (final s in _subscriptions) {
      s.cancel();
    }
    super.dispose();
  }
}
