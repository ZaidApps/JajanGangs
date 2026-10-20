import 'dart:math' as math;

class MapArea {
  const MapArea(
    this.latitude,
    this.longitude, {
    this.radius = 2000,
    this.isFallback = false,
  });
  final double latitude;
  final double longitude;
  final double radius;
  final bool isFallback;
  static const jakarta = MapArea(-6.20, 106.84, isFallback: true);
}

enum FoodKind { noodles, coffee, satay, burger, anything, chicken, pizza }

class MapJajan {
  const MapJajan(
    this.id,
    this.kind,
    this.latitude,
    this.longitude,
    this.members,
    this.capacity, {
    this.cravingKey,
    this.creatorName,
    this.creatorAvatarId,
    this.description = '',
    this.expiresAt,
    this.scheduledAt,
  });
  final String id;
  final FoodKind kind;
  final double latitude;
  final double longitude;
  final int members;
  final int capacity;
  final String? cravingKey;
  final String? creatorName;
  final String? creatorAvatarId;
  final String description;
  final DateTime? expiresAt;
  final DateTime? scheduledAt;
  bool get isDemo => cravingKey == null;

  double distanceKm(MapArea area) {
    final lat = (latitude - area.latitude) * 111.32;
    final lng =
        (((longitude - area.longitude + 180) % 360) - 180) *
        111.32 *
        math.cos(area.latitude * math.pi / 180);
    return (math.sqrt(lat * lat + lng * lng) * 2).round() / 2;
  }

  static List<MapJajan> around(MapArea area) {
    final longitudeScale = math.max(
      .2,
      math.cos(area.latitude * math.pi / 180),
    );
    MapJajan event(
      String id,
      FoodKind food,
      double north,
      double east,
      int members,
      int capacity,
    ) => MapJajan(
      id,
      food,
      (area.latitude + north).clamp(-85.0, 85.0).toDouble(),
      ((area.longitude + east / longitudeScale + 180) % 360) - 180,
      members,
      capacity,
    );
    return [
      event('noodles', FoodKind.noodles, .004, -.006, 3, 5),
      event('coffee', FoodKind.coffee, .011, .010, 2, 4),
      event('satay', FoodKind.satay, -.009, .007, 4, 6),
      event('burger', FoodKind.burger, -.006, -.013, 2, 5),
    ];
  }
}
