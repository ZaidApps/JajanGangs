import 'package:flutter/foundation.dart';

class AppConfig {
  const AppConfig({required this.mapboxToken});

  factory AppConfig.fromEnvironment() => const AppConfig(
    mapboxToken: String.fromEnvironment('MAPBOX_ACCESS_TOKEN'),
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
