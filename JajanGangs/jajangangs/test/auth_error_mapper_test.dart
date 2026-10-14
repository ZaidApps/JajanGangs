import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:jajangangs/services/auth_error_mapper.dart';

void main() {
  test(
    'recognizes Android wrapped configuration errors without leaking details',
    () {
      final failure = mapAuthFailure(
        FirebaseAuthException(
          code: 'internal-error',
          message: 'CONFIGURATION_NOT_FOUND private@example.com secret-token',
        ),
      );
      expect(failure.message, contains('not configured'));
      expect(failure.message, isNot(contains('private@example.com')));
      expect(failure.message, isNot(contains('secret-token')));
    },
  );

  test('disabled email provider gets an actionable message', () {
    final failure = mapAuthFailure(
      FirebaseAuthException(code: 'operation-not-allowed'),
    );
    expect(failure.message, contains('not been enabled'));
  });

  test('unknown Firebase failures retain only the safe diagnostic code', () {
    final failure = mapAuthFailure(
      FirebaseAuthException(
        code: 'internal-error',
        message: 'private@example.com secret-token',
      ),
    );
    expect(failure.message, contains('internal-error'));
    expect(failure.message, isNot(contains('secret-token')));
    expect(
      mapAuthFailure(FirebaseAuthException(code: 'private@example.com'))
          .message,
      contains('(unknown)'),
    );
  });

  test('Google configuration failure differs from cancellation', () {
    final failure = mapAuthFailure(
      const GoogleSignInException(
        code: GoogleSignInExceptionCode.clientConfigurationError,
      ),
    );
    expect(failure.message, contains('setup is incomplete'));
    expect(failure.cancelled, isFalse);
    expect(
      mapAuthFailure(
        const GoogleSignInException(code: GoogleSignInExceptionCode.canceled),
      ).cancelled,
      isTrue,
    );
  });
}
