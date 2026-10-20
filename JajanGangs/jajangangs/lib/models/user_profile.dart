import 'auth_session.dart';

abstract final class AvatarCatalog {
  // Stable IDs are stored in Firestore; do not rename IDs after release.
  static const ids = [
    'anime_01',
    'anime_02',
    'anime_03',
    'anime_04',
    'anime_05',
    'anime_06',
    'anime_07',
    'anime_08',
    'anime_09',
    'anime_10',
  ];
  static const defaultId = 'anime_01';
  // Keep stored profiles and historical message/member snapshots valid.
  // Legacy characters display the default portrait without database writes.
  static const legacyIds = [
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
  static bool contains(String? id) =>
      ids.contains(id) || legacyIds.contains(id);
  static String displayId(String? id) => ids.contains(id) ? id! : defaultId;
  static String asset(String? id) => 'assets/avatars/${displayId(id)}.webp';
  static String motionAsset(String? id) =>
      'assets/avatars/motion/${displayId(id)}.webp';
}

class UserProfile {
  const UserProfile({this.name, this.avatarId, this.bio = ''});
  final String bio;
  final String? name;
  final String? avatarId;
  bool get isComplete =>
      AuthValidation.name(name) == null && AvatarCatalog.contains(avatarId);
}
