import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSound extends ChangeNotifier with WidgetsBindingObserver {
  NotificationSound._() {
    WidgetsBinding.instance.addObserver(this);
    ready = _restore();
  }
  static final instance = NotificationSound._();
  static const channel = MethodChannel('jajangangs/notification_sound');
  final preferences = SharedPreferencesAsync();
  late final Future<void> ready;
  bool enabled = true, saving = false;
  String? activeChat;
  DateTime foregroundSince = DateTime.now();
  DateTime? lastPlayed;
  Future<void> _restore() async {
    try {
      enabled = await preferences.getBool('notification_sound') ?? true;
    } catch (_) {}
    notifyListeners();
  }

  Future<bool> setEnabled(bool value) async {
    if (saving) return false;
    saving = true;
    notifyListeners();
    try {
      await ready;
      await preferences.setBool('notification_sound', value);
      enabled = value;
      return true;
    } catch (_) {
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) foregroundSince = DateTime.now();
  }

  Future<void> play() async {
    await ready;
    final now = DateTime.now();
    if (!enabled ||
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed ||
        (lastPlayed != null &&
            now.difference(lastPlayed!) < const Duration(seconds: 3)))
      return;
    lastPlayed = now;
    try {
      await channel.invokeMethod<void>('play');
    } catch (_) {
      /* Audio must never interrupt notifications. */
    }
  }
}
