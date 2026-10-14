import 'home_map_state.dart';

enum Craving { anything, fastFood, chicken, pizza, cafe, streetFood }

extension CravingDetails on Craving {
  String get key => switch (this) {
    Craving.anything => 'cravingAnything',
    Craving.fastFood => 'cravingFastFood',
    Craving.chicken => 'cravingChicken',
    Craving.pizza => 'cravingPizza',
    Craving.cafe => 'cravingCafe',
    Craving.streetFood => 'cravingStreetFood',
  };
  FoodKind get foodKind => switch (this) {
    Craving.anything => FoodKind.anything,
    Craving.fastFood => FoodKind.burger,
    Craving.chicken => FoodKind.chicken,
    Craving.pizza => FoodKind.pizza,
    Craving.cafe => FoodKind.coffee,
    Craving.streetFood => FoodKind.satay,
  };
}

class JajanDraft {
  const JajanDraft({
    required this.id,
    required this.craving,
    required this.capacity,
    required this.area,
    this.description = '',
    this.joinPolicy = 'private',
  });
  final String joinPolicy;
  bool get isPublic => joinPolicy == 'public';
  final String description;
  final String id;
  final Craving craving;
  final int capacity;
  final MapArea area;
  Map<String, dynamic> toJson() => {
    'id': id,
    'description': description,
    'joinPolicy': joinPolicy,
    'craving': craving.name,
    'capacity': capacity,
    'latCell': (area.latitude / .02).round(),
    'lngCell': (area.longitude / .02).round(),
    'radiusMeters': area.radius.ceil(),
  };
  factory JajanDraft.fromJson(Map<String, dynamic> data) => JajanDraft(
    id: data['id'] as String,
    joinPolicy: data['joinPolicy'] as String? ?? 'private',
    description: data['description'] as String? ?? '',
    craving: Craving.values.byName(data['craving'] as String),
    capacity: data['capacity'] as int,
    area: MapArea(
      (data['latCell'] as num).toDouble() * .02,
      (data['lngCell'] as num).toDouble() * .02,
      radius: (data['radiusMeters'] as num).toDouble(),
    ),
  );
}

class JajanEvent {
  const JajanEvent({
    required this.id,
    required this.creatorId,
    required this.craving,
    required this.capacity,
    required this.area,
    required this.createdAt,
    this.description = '',
    this.joinPolicy = 'private',
    this.memberCount = 1,
    this.state = 'OPEN',
    this.creatorName,
    this.creatorAvatarId,
    this.memberIds = const [],
  });
  final String joinPolicy;
  bool get isPublic => joinPolicy == 'public';
  final String description;
  final String id;
  final String creatorId;
  final Craving craving;
  final int capacity;
  final MapArea area;
  final DateTime createdAt;
  final int memberCount;
  final String state;
  final String? creatorName;
  final String? creatorAvatarId;
  final List<String> memberIds;
  DateTime get expiresAt => createdAt.add(const Duration(minutes: 45));
  bool get isActive =>
      [
        'OPEN',
        'DECIDING',
        'DESTINATION_SELECTED',
        'ON_THE_WAY',
      ].contains(state) &&
      expiresAt.isAfter(DateTime.now().toUtc());
  MapJajan toMap() => MapJajan(
    id,
    craving.foodKind,
    area.latitude,
    area.longitude,
    memberCount,
    capacity,
    cravingKey: craving.key,
    expiresAt: expiresAt,
  );
}
