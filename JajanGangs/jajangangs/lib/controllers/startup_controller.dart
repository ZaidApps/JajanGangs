import 'package:flutter/foundation.dart';

import '../models/startup_state.dart';

class StartupController extends ChangeNotifier {
  StartupController({required this.initialize});
  final Future<void> Function() initialize;
  StartupState _state = const StartupState(StartupStatus.loading);
  StartupState get state => _state;
  bool _running = false;
  bool _disposed = false;

  Future<void> start() async {
    if (_running || _disposed) return;
    _running = true;
    _setState(const StartupState(StartupStatus.loading));
    try {
      await initialize();
      _setState(const StartupState(StartupStatus.ready));
    } catch (error) {
      _setState(
        StartupState(
          StartupStatus.failed,
          message: error is FormatException
              ? error.message
              : error is UnsupportedError
              ? error.message
              : 'startupError',
        ),
      );
    } finally {
      _running = false;
    }
  }

  void _setState(StartupState value) {
    if (_disposed) return;
    _state = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
