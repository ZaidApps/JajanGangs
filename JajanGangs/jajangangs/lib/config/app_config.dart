import 'package:flutter/foundation.dart';

class AppConfig {
  const AppConfig({required this.mapboxToken});

  factory AppConfig.fromEnvironment() => const AppConfig(
    // Public client token bundled for normal Android and iOS builds.
    // A dart-define can still override it for another environment.
    mapboxToken: String.fromEnvironment(
      'MAPBOX_ACCESS_TOKEN',
      defaultValue: 'pk.eyJ1IjoiemFpZGFsemJ1biIsImEiOiJjbXVpZzVmdmkxYWN3MzFvZWE3NDEzdW5wIn0.JkTUw09o9T16hdcHp90XPA',
    ),
  );

  final String mapboxToken;

  void validate() {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      throw UnsupportedError('mobileOnly');
    }
    if (!mapboxToken.startsWith('pk.') || mapboxToken.split('.').length != 3) {
      throw const FormatException('mapTokenMissing');
    }
  }
}
