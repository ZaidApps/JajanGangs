import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/auth_session.dart';
import '../models/food_wheel.dart';
import '../services/food_wheel_service.dart';

class FoodWheelController extends ChangeNotifier {
  FoodWheelController(this.eventId, this.uid);
  final String eventId, uid;
  final service = FoodWheelService();
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? sub;
  Timer? timeout;
  FoodWheel? wheel;
  bool loading = true, busy = false, confirmed = false, disposed = false;
  String? error;
  void start() {
    sub?.cancel();
    timeout?.cancel();
    loading = true;
    error = null;
    confirmed = false;
    notifyListeners();
    timeout = Timer(const Duration(seconds: 15), () {
      if (!disposed && !confirmed) {
        loading = false;
        error = 'wheelError';
        notifyListeners();
      }
    });
    sub = service
        .current(eventId)
        .snapshots(includeMetadataChanges: true)
        .listen(
          (s) {
            if (disposed) return;
            confirmed = !s.metadata.isFromCache && !s.metadata.hasPendingWrites;
            if (confirmed) {
              timeout?.cancel();
              error = null;
              loading = false;
              wheel = s.exists ? FoodWheel(s.data()!) : null;
            }
            notifyListeners();
          },
          onError: (Object e) {
            if (!disposed) {
              timeout?.cancel();
              loading = false;
              confirmed = false;
              error = 'wheelError';
              notifyListeners();
            }
          },
        );
  }

  Future<void> act(Future<void> Function() action) async {
    if (busy || !confirmed) return;
    busy = true;
    error = null;
    notifyListeners();
    try {
      await action();
    } catch (e) {
      if (!disposed) error = e is AuthFailure ? e.message : 'wheelError';
    } finally {
      if (!disposed) {
        busy = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    disposed = true;
    sub?.cancel();
    timeout?.cancel();
    super.dispose();
  }
}
