import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/auth_session.dart';

// Raw SDK exceptions may contain personal data. Log only their codes.
String _safeCode(String code) =>
    RegExp(r'^[a-zA-Z0-9_-]{1,80}$').hasMatch(code) ? code : 'unknown';
AuthFailure mapAuthFailure(Object error) {
  if (error is AuthFailure) return error;
  if (error is TimeoutException) return const AuthFailure('timeoutError');
  if (error is GoogleSignInException) {
    if (kDebugMode) debugPrint('[Auth] google/${_safeCode(error.code.name)}');
    if (error.code.name == 'clientConfigurationError' ||
        error.code.name == 'providerConfigurationError') {
      return const AuthFailure('googleSetup');
    }
    if (error.code == GoogleSignInExceptionCode.canceled) {
      return const AuthFailure('googleCancelled', cancelled: true);
    }
    return const AuthFailure('googleUnavailable');
  }
  if (error is FirebaseException) {
    // Android can wrap a backend configuration failure in internal-error.
    // Inspect only known identifiers, never display or log the raw message.
    var code = error.code;
    if (code == 'internal-error' || code == 'unknown') {
      final detail = error.message ?? '';
      const known = {
        'CONFIGURATION_NOT_FOUND': 'configuration-not-found',
        'OPERATION_NOT_ALLOWED': 'operation-not-allowed',
        'PASSWORD_LOGIN_DISABLED': 'operation-not-allowed',
        'API_KEY_INVALID': 'invalid-api-key',
        'API_KEY_SERVICE_BLOCKED': 'app-not-authorized',
        'API_KEY_ANDROID_APP_BLOCKED': 'app-not-authorized',
        'PROJECT_NOT_FOUND': 'project-not-found',
      };
      for (final entry in known.entries) {
        if (detail.contains(entry.key)) {
          code = entry.value;
          break;
        }
      }
    }
    if (kDebugMode)
      debugPrint('[Auth] ${_safeCode(error.plugin)}/${_safeCode(code)}');
    final message = switch (code) {
      'invalid-email' => 'emailInvalid',
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' ||
      'invalid-login-credentials' => 'wrongCredentials',
      'email-already-in-use' => 'emailInUse',
      'weak-password' ||
      'password-does-not-meet-requirements' => 'weakPassword',
      'network-request-failed' || 'unavailable' => 'networkError',
      'too-many-requests' || 'resource-exhausted' => 'tooManyRequests',
      'user-disabled' => 'accountDisabled',
      'operation-not-allowed' => 'providerDisabled',
      'configuration-not-found' ||
      'project-not-found' => 'registrationNotConfigured',
      'invalid-api-key' ||
      'app-not-authorized' ||
      'invalid-app-credential' => 'appUnauthorized',
      'account-exists-with-different-credential' => 'credentialConflict',
      'permission-denied' => 'profileDenied',
      'popup-closed-by-user' || 'cancelled-popup-request' => 'googleCancelled',
      'popup-blocked' => 'popupBlocked',
      'unauthorized-domain' => 'domainUnauthorized',
      'user-token-expired' || 'requires-recent-login' => 'sessionExpired',
      _ => 'signInFailed:${_safeCode(code)}',
    };
    return AuthFailure(
      message,
      cancelled: [
        'popup-closed-by-user',
        'cancelled-popup-request',
      ].contains(error.code),
    );
  }
  return const AuthFailure('signInConnection');
}
