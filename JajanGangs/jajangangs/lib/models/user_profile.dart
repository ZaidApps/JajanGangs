import 'auth_session.dart';

abstract final class AvatarCatalog {
  // Stable IDs are stored in Firestore; do not rename IDs after release.
  static const ids = [
    'cat',
    'frog',
    'robot',
    'panda',
    'fox',
    'bunny',
    'bear',
    'alien',
    'penguin',
    'monster',
  ];
  static bool contains(String? id) => ids.contains(id);
}

class UserProfile {
  const UserProfile({this.name, this.avatarId});
  final String? name;
  final String? avatarId;
  bool get isComplete =>
      AuthValidation.name(name) == null && AvatarCatalog.contains(avatarId);
}
