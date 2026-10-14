import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Public console broadcasts only; no server credentials or Firestore writes.
class AnnouncementService with WidgetsBindingObserver {
  AnnouncementService({
    required this.explainPermission,
    required this.onMessage,
  }) {
    WidgetsBinding.instance.addObserver(this);
  }

  static const topic = 'jajan_announcements';
  final Future<bool> Function() explainPermission;
  final void Function(RemoteMessage) onMessage;
  final _preferences = SharedPreferencesAsync();
  StreamSubscription<String>? _tokens;
  StreamSubscription<RemoteMessage>? _messages;
  Timer? _retry;
  bool _member = false, _running = false, _disposed = false;
  bool? _applied;
  int _attempt = 0;

  static bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  // Called only once Firebase initialization has finished.
  void updateMember(bool member) {
    if (!supported || _disposed || Firebase.apps.isEmpty) return;
    if (_member != member) {
      _member = member;
      _attempt = 0;
      _retry?.cancel();
    }
    unawaited(_sync());
  }

  Future<void> _sync() async {
    if (!supported ||
        _running ||
        _disposed ||
        Firebase.apps.isEmpty ||
        _applied == _member)
      return;
    _running = true;
    final desired = _member;
    try {
      final messaging = FirebaseMessaging.instance;
      _tokens ??= messaging.onTokenRefresh.listen(
        (_) {
          _applied = null;
          unawaited(_sync());
        },
        onError: (Object error) =>
            debugPrint('[Announcements] token refresh: $error'),
      );
      _messages ??= FirebaseMessaging.onMessage.listen((message) {
        if (_member && !_disposed) onMessage(message);
      });
      if (desired) {
        var settings = await messaging.getNotificationSettings();
        final asked =
            await _preferences.getBool('announcements_permission_asked') ??
            false;
        if (!asked &&
            settings.authorizationStatus != AuthorizationStatus.authorized) {
          final allow = await explainPermission();
          if (_disposed || !_member) return;
          await _preferences.setBool('announcements_permission_asked', true);
          if (allow) settings = await messaging.requestPermission();
        }
        if (_disposed || !_member) return;
        if (settings.authorizationStatus != AuthorizationStatus.authorized &&
            settings.authorizationStatus != AuthorizationStatus.provisional) {
          // Recheck on resume, in case permission is enabled in device settings.
          return;
        }
        if (defaultTargetPlatform == TargetPlatform.iOS &&
            await messaging.getAPNSToken() == null) {
          throw StateError('APNs token is not ready');
        }
        await messaging.setAutoInitEnabled(true);
        await messaging.subscribeToTopic(topic);
      } else {
        // Persisted SDK subscriptions may survive a previous app session.
        if (defaultTargetPlatform == TargetPlatform.iOS &&
            await messaging.getAPNSToken() == null)
          return;
        await messaging.unsubscribeFromTopic(topic);
      }
      _applied = desired;
      _attempt = 0;
      debugPrint(
        '[Announcements] ${desired ? 'Subscribed' : 'Unsubscribed'}: $topic',
      );
    } catch (error) {
      debugPrint('[Announcements] Subscription pending: $error');
      if (!_disposed && _attempt < 5) {
        _retry?.cancel();
        _retry = Timer(
          Duration(seconds: 5 * ++_attempt),
          () => unawaited(_sync()),
        );
      }
    } finally {
      _running = false;
      if (!_disposed && desired != _member) unawaited(_sync());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _attempt = 0;
      unawaited(_sync());
    }
  }

  void dispose() {
    _disposed = true;
    _retry?.cancel();
    _tokens?.cancel();
    _messages?.cancel();
    WidgetsBinding.instance.removeObserver(this);
  }
}
