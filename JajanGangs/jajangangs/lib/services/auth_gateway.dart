import '../models/user_profile.dart';
import '../models/auth_session.dart';

abstract interface class AuthGateway {
  Future<void> initialize();
  AuthSession? get session;
  Stream<AuthSession?> get sessions;
  Future<void> login(String email, String password);
  Future<void> register(
    String name,
    String email,
    String password,
    String avatarId,
  );
  Future<void> google();
  Future<void> sendVerification();
  Future<void> refreshUser();
  Future<void> resetPassword(String email);
  Future<UserProfile?> readProfile(String uid);
  Future<String?> readRegistrationAvatar(String uid);
  Future<void> saveProfile(String uid, String name, String avatarId);
  Future<void> signOut();
}
