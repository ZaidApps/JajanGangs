enum AuthPage {
  welcome,
  login,
  register,
  resetPassword,
  verifyEmail,
  profile,
  loadingProfile,
  profileError,
  complete,
}

class AuthSession {
  const AuthSession({
    required this.uid,
    required this.email,
    required this.verified,
    this.displayName,
    this.passwordAccount = false,
  });
  final String uid;
  final String email;
  final bool verified;
  final String? displayName;
  final bool passwordAccount;
  String get key => '$uid:$verified';
}

class AuthFailure implements Exception {
  const AuthFailure(this.message, {this.cancelled = false});
  final String message;
  final bool cancelled;
}

abstract final class AuthValidation {
  static String? email(String? value) {
    final email = (value ?? '').trim();
    if (email.isEmpty) return 'emailRequired';
    if (email.length > 254 ||
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'emailInvalid';
    }
    return null;
  }

  static String? password(String? value, {bool creating = false}) {
    if (value == null || value.isEmpty) return 'passwordRequired';
    if (creating && value.length < 8) return 'passwordShort';
    if (value.length > 4096) return 'passwordLong';
    return null;
  }

  static String cleanName(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ');
  static String? name(String? value) {
    final name = cleanName(value ?? '');
    if (name.isEmpty) return 'nameRequired';
    if (name.length > 50) return 'nameLong';
    if (RegExp(r'[\x00-\x1F\x7F]').hasMatch(name)) return 'nameInvalid';
    return null;
  }
}
