import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/auth_session.dart';
import '../models/gang_poll.dart';
import '../services/gang_poll_service.dart';

class GangPollController extends ChangeNotifier {
  GangPollController(this.id, this.uid);
  final String id, uid;
  final service = GangPollService();
  GangPoll? poll;
  bool loading = true, busy = false, confirmed = false, _disposed = false;
  String? error;
  StreamSubscription? _subscription;
  Timer? _timeout;
  void start() {
    _subscription?.cancel();
    _timeout?.cancel();
    loading = true;
    confirmed = false;
    error = null;
    _timeout = Timer(const Duration(seconds: 15), () {
      if (_disposed || confirmed) return;
      loading = false;
      error = 'pollError';
      notifyListeners();
    });
    _subscription = service
        .poll(id)
        .snapshots(includeMetadataChanges: true)
        .listen(
          (doc) {
            if (_disposed) return;
            try {
              poll = doc.exists ? GangPoll(doc.data()!) : null;
            } catch (e) {
              poll = null;
              loading = false;
              confirmed = false;
              error = 'pollError';
              notifyListeners();
              return;
            }
            confirmed =
                !doc.metadata.isFromCache && !doc.metadata.hasPendingWrites;
            loading = false;
            if (confirmed) _timeout?.cancel();
            error = null;
            notifyListeners();
          },
          onError: (Object e) {
            if (_disposed) return;
            loading = false;
            confirmed = false;
            error = 'pollError';
            notifyListeners();
          },
        );
    if (!_disposed) notifyListeners();
  }

  Future<bool> run(Future<void> Function() action) async {
    if (busy || _disposed) return false;
    busy = true;
    error = null;
    notifyListeners();
    try {
      await action();
      return true;
    } catch (e) {
      error = e is AuthFailure ? e.message : 'pollError';
      if (kDebugMode) debugPrint('[GangPoll] $e');
      return false;
    } finally {
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _timeout?.cancel();
    _subscription?.cancel();
    super.dispose();
  }
}
