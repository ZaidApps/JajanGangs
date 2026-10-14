import 'package:firebase_core/firebase_core.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../config/app_config.dart';

class StartupService {
  Future<void> initialize(AppConfig config) async {
    config.validate();
    // Native Firebase configuration files are the source of truth.
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
    MapboxOptions.setAccessToken(config.mapboxToken);
  }
}
