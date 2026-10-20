import '../models/user_profile.dart';

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/auth_session.dart';
import '../services/auth_gateway.dart';

class AuthController extends ChangeNotifier {
  AuthController(this.gateway, {DateTime Function()? now})
    : _now = now ?? DateTime.now;
  final AuthGateway gateway;
  final DateTime Function() _now;
  AuthPage page = AuthPage.welcome;
  AuthSession? user;
  String bio = '';
  String? name;
  String? avatarId;
  String? error;
  String? notice;
  bool busy = false;
  bool restoring = false;
  bool _ready = false;
  bool _disposed = false;
  Future<void>? _initialization;
  StreamSubscription<AuthSession?>? _subscription;
  String? _resolvedKey;
  int _generation = 0;
  Timer? _cooldownTimer;
  DateTime? _verificationSentAt;
  DateTime? _resetSentAt;
  int get verificationWait => _remaining(_verificationSentAt);
  int get resetWait => _remaining(_resetSentAt);
  int _remaining(DateTime? time) =>
      time == null ? 0 : (60 - _now().difference(time).inSeconds).clamp(0, 60);

  void _emit() {
    if (!_disposed) notifyListeners();
  }

  String _message(Object e) => e is AuthFailure ? e.message : 'genericError';

  Future<void> restore() async {
    restoring = true;
    _emit();
    try {
      await _ensureReady();
      await _resolve();
    } catch (_) {
      /* Welcome remains accessible when backend setup is unavailable. */
    } finally {
      restoring = false;
      _emit();
    }
  }

  Future<void> _ensureReady() async {
    if (_ready) return;
    _initialization ??= gateway.initialize();
    try {
      await _initialization!.timeout(const Duration(seconds: 20));
      if (_disposed) return;
      _ready = true;
      _subscription ??= gateway.sessions.listen(
        (session) {
          if (!busy && !restoring && !_disposed) unawaited(_resolve());
        },
        onError: (Object e) {
          error = _message(e);
          _emit();
        },
      );
    } catch (_) {
      _initialization = null;
      rethrow;
    }
  }

  void show(AuthPage destination) {
    if (busy || restoring || _disposed) return;
    if (user != null &&
        [
          AuthPage.welcome,
          AuthPage.login,
          AuthPage.register,
          AuthPage.resetPassword,
        ].contains(destination))
      return;
    page = destination;
    error = null;
    notice = null;
    _emit();
  }

  Future<void> _resolve({bool force = false}) async {
    if (_disposed || !_ready) return;
    final session = gateway.session;
    if (session == null) {
      final wasSignedIn = user != null;
      _generation++;
      _resolvedKey = null;
      user = null;
      bio = '';
      name = null;
      avatarId = null;
      if (wasSignedIn) {
        page = AuthPage.welcome;
        error = null;
        notice = null;
      }
      _emit();
      return;
    }
    user = session;
    if (!force && _resolvedKey == session.key) return;
    _resolvedKey = session.key;
    final generation = ++_generation;
    error = null;
    notice = null;
    if (!session.verified) {
      page = AuthPage.verifyEmail;
      _emit();
      return;
    }
    page = AuthPage.loadingProfile;
    _emit();
    try {
      var profile = await gateway.readProfile(session.uid);
      if (_disposed || generation != _generation) return;
      name = profile?.name ?? session.displayName;
      avatarId = profile?.avatarId;
      // Email registration already required both fields. Finish the verified
      // Firestore profile from the UID-scoped draft without asking twice.
      if (profile?.isComplete != true && session.passwordAccount) {
        final draft = await gateway.readRegistrationAvatar(session.uid);
        if (_disposed || generation != _generation) return;
        if (AvatarCatalog.contains(draft) &&
            AuthValidation.name(name) == null) {
          final cleanName = AuthValidation.cleanName(name!);
          await gateway.saveProfile(session.uid, cleanName, avatarId ?? draft!);
          profile = await gateway.readProfile(session.uid);
        }
      }
      if (_disposed || generation != _generation) return;
      bio = profile?.bio ?? '';
      name = profile?.name ?? name;
      avatarId = profile?.avatarId;
      // Google users and old name-only profiles must choose their character.
      page = profile?.isComplete == true ? AuthPage.complete : AuthPage.profile;
    } catch (e) {
      if (_disposed || generation != _generation) return;
      error = _message(e);
      page = AuthPage.profileError;
    }
    _emit();
  }

  Future<void> _authenticate(
    Future<void> Function() action, {
    bool registration = false,
  }) async {
    if (busy || restoring || _disposed) return;
    busy = true;
    error = null;
    notice = null;
    _emit();
    Object? failure;
    try {
      await _ensureReady();
      if (!_disposed) await action();
    } catch (e) {
      failure = e;
    }
    if (!_disposed) {
      await _resolve();
      if (_disposed) return;
      if (failure != null && !(failure is AuthFailure && failure.cancelled))
        error = _message(failure);
      if (registration &&
          gateway.session != null &&
          !gateway.session!.verified) {
        try {
          await gateway.sendVerification();
          _verificationSentAt = _now();
          _tick();
          notice = 'verificationSent';
        } catch (e) {
          error = _message(e);
        }
      }
      busy = false;
      _emit();
    }
  }

  Future<void> login(String email, String password) async {
    final validation =
        AuthValidation.email(email) ?? AuthValidation.password(password);
    if (validation != null) {
      error = validation;
      _emit();
      return;
    }
    await _authenticate(() => gateway.login(email.trim(), password));
  }

  Future<void> register(
    String name,
    String email,
    String password,
    String? selectedAvatar, {
    String bio = '',
  }) async {
    final validation =
        (bio.trim().runes.length > 150 ? 'bioLong' : null) ??
        AuthValidation.name(name) ??
        AuthValidation.email(email) ??
        AuthValidation.password(password, creating: true) ??
        (AvatarCatalog.contains(selectedAvatar) ? null : 'avatarRequired');
    if (validation != null) {
      error = validation;
      _emit();
      return;
    }
    await _authenticate(
      () => gateway.register(
        AuthValidation.cleanName(name),
        email.trim(),
        password,
        selectedAvatar!,
        bio: bio,
      ),
      registration: true,
    );
  }

  Future<void> google() => _authenticate(gateway.google);

  Future<void> resendVerification() async {
    if (busy || verificationWait > 0 || user == null || _disposed) return;
    busy = true;
    error = null;
    notice = null;
    _emit();
    try {
      await gateway.sendVerification();
      _verificationSentAt = _now();
      _tick();
      notice = 'verificationSent';
    } catch (e) {
      error = _message(e);
    }
    busy = false;
    _emit();
  }

  Future<void> checkVerification() async {
    if (busy || _disposed) return;
    busy = true;
    error = null;
    notice = null;
    _emit();
    try {
      await gateway.refreshUser();
      await _resolve(force: true);
      if (user != null && !user!.verified) notice = 'notVerified';
    } catch (e) {
      error = _message(e);
    }
    busy = false;
    _emit();
  }

  Future<void> sendReset(String email) async {
    if (busy || restoring || resetWait > 0 || _disposed) return;
    final validation = AuthValidation.email(email);
    if (validation != null) {
      error = validation;
      _emit();
      return;
    }
    busy = true;
    error = null;
    notice = null;
    _emit();
    try {
      await _ensureReady();
      await gateway.resetPassword(email.trim());
      _resetSentAt = _now();
      _tick();
      notice = 'resetSent';
    } catch (e) {
      error = _message(e);
    }
    busy = false;
    _emit();
  }

  Future<void> saveProfile(
    String value,
    String? selectedAvatar, {
    String bio = '',
  }) async {
    if (busy || user == null || !user!.verified || _disposed) return;
    final validation =
        (bio.trim().runes.length > 150 ? 'bioLong' : null) ??
        AuthValidation.name(value) ??
        (AvatarCatalog.contains(selectedAvatar) ? null : 'avatarRequired');
    if (validation != null) {
      error = validation;
      _emit();
      return;
    }
    busy = true;
    error = null;
    _emit();
    final uid = user!.uid;
    final generation = _generation;
    try {
      await gateway.saveProfile(
        uid,
        AuthValidation.cleanName(value),
        selectedAvatar!,
        bio: bio,
      );
      if (!_disposed && generation == _generation) {
        this.bio = bio.trim();
        name = AuthValidation.cleanName(value);
        avatarId = selectedAvatar;
        page = AuthPage.complete;
      }
    } catch (e) {
      error = _message(e);
    }
    busy = false;
    _emit();
  }

  Future<void> retryProfile() async {
    if (busy || _disposed) return;
    busy = true;
    _emit();
    await _resolve(force: true);
    busy = false;
    _emit();
  }

  Future<void> signOut() async {
    if (busy || _disposed) return;
    busy = true;
    error = null;
    _emit();
    try {
      await gateway.signOut();
      await _resolve();
    } catch (e) {
      error = _message(e);
    }
    busy = false;
    _emit();
  }

  void _tick() {
    if (_disposed) return;
    _cooldownTimer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (verificationWait == 0 && resetWait == 0) {
        _cooldownTimer?.cancel();
        _cooldownTimer = null;
      }
      _emit();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _subscription?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }
}
