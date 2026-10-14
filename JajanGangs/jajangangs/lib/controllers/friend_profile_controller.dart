import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/friendship.dart';
import '../models/auth_session.dart';
import '../services/friends_service.dart';

class FriendProfileController extends ChangeNotifier {
  FriendProfileController(this.uid, this.peer);
  final String uid, peer;
  final service = FriendsService();
  Friendship? friendship;
  bool sendingRequest = false, optimisticSent = false;
  String? error;
  bool loading = true, busy = false, confirmed = false, _disposed = false;
  StreamSubscription? _subscription;
  Timer? _timer;
  void start() {
    _subscription?.cancel();
    _timer?.cancel();
    loading = true;
    confirmed = false;
    error = null;
    _timer = Timer(const Duration(seconds: 15), () {
      if (_disposed || confirmed) return;
      loading = false;
      error = 'friendError';
      notifyListeners();
    });
    _subscription = service
        .relation(uid, peer)
        .snapshots(includeMetadataChanges: true)
        .listen(
          (doc) {
            if (_disposed) return;
            confirmed =
                !doc.metadata.isFromCache && !doc.metadata.hasPendingWrites;
            if (!doc.metadata.hasPendingWrites) {
              friendship = doc.exists ? Friendship(doc) : null;
            }
            if (confirmed && friendship != null && !sendingRequest)
              optimisticSent = false;
            loading = false;
            error = null;
            if (confirmed) _timer?.cancel();
            notifyListeners();
          },
          onError: (Object e) {
            if (!_disposed) {
              error = 'friendError';
              loading = false;
              confirmed = false;
              notifyListeners();
            }
          },
        );
    if (!_disposed) notifyListeners();
  }

  Future<void> act(Future<void> Function() action) async {
    if (busy || !confirmed || _disposed) return;
    busy = true;
    error = null;
    notifyListeners();
    try {
      await action();
    } catch (e) {
      error = e is AuthFailure ? e.message : 'friendError';
      if (kDebugMode) debugPrint('[Friends] ${e.runtimeType}');
    } finally {
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> send(String eventId) async {
    if (busy || !confirmed || _disposed) return;
    sendingRequest = true;
    optimisticSent = true;
    busy = true;
    error = null;
    notifyListeners();
    try {
      await service.send(uid, peer, eventId);
      if (friendship?.status == 'REQUESTED' ||
          friendship?.status == 'ACCEPTED') {
        optimisticSent = false;
      }
    } catch (e) {
      optimisticSent = false;
      error = e is AuthFailure ? e.message : 'friendSendFailed';
      if (kDebugMode) debugPrint('[Friends] send failed: ${e.runtimeType}');
    } finally {
      busy = false;
      sendingRequest = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }
}
