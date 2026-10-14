import 'package:firebase_core/firebase_core.dart';

/// Optional web configuration. Native apps use their supplied Firebase files.
abstract final class FirebaseWebConfig {
  static const appId = String.fromEnvironment('FIREBASE_WEB_APP_ID');
  static const apiKey = String.fromEnvironment('FIREBASE_WEB_API_KEY');
  static const projectId = String.fromEnvironment('FIREBASE_WEB_PROJECT_ID');
  static const senderId = String.fromEnvironment(
    'FIREBASE_WEB_MESSAGING_SENDER_ID',
  );
  static const authDomain = String.fromEnvironment('FIREBASE_WEB_AUTH_DOMAIN');
  static bool get configured => [
    appId,
    apiKey,
    projectId,
    senderId,
    authDomain,
  ].every((v) => v.isNotEmpty);
  static FirebaseOptions get options => const FirebaseOptions(
    apiKey: apiKey,
    appId: appId,
    messagingSenderId: senderId,
    projectId: projectId,
    authDomain: authDomain,
  );
}
