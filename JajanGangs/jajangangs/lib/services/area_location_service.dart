import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/home_map_state.dart';

class AreaLocationResult {
  const AreaLocationResult(this.area, this.messageKey);
  final MapArea area;
  final String messageKey;
}

class AreaLocationService {
  // Home and Create can overlap during navigation. Share the in-flight lookup
  // so the OS never receives two concurrent permission/location requests.
  static Future<AreaLocationResult>? _inFlight;
  Future<AreaLocationResult> locate() async {
    final existing = _inFlight;
    if (existing != null) return existing;
    final elapsed = Stopwatch()..start();
    final operation = _locate();
    _inFlight = operation;
    try {
      final result = await operation;
      if (kDebugMode) {
        debugPrint(
          'Area lookup result: ${result.messageKey} (${elapsed.elapsedMilliseconds}ms)',
        );
      }
      return result;
    } finally {
      elapsed.stop();
      if (identical(_inFlight, operation)) _inFlight = null;
    }
  }

  Future<AreaLocationResult> _locate() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled().timeout(
        const Duration(seconds: 3),
      )) {
        return const AreaLocationResult(MapArea.jakarta, 'locationOff');
      }
      var permission = await Geolocator.checkPermission().timeout(
        const Duration(seconds: 3),
      );
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        return const AreaLocationResult(MapArea.jakarta, 'locationBlocked');
      }
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return const AreaLocationResult(MapArea.jakarta, 'locationDenied');
      }
      // A recent OS fix is sufficient for our coarse map cells. Never persist
      // the raw coordinates ourselves, and never reuse a stale/poor fix.
      try {
        final recent = await Geolocator.getLastKnownPosition().timeout(
          const Duration(seconds: 1),
        );
        if (recent != null && _usable(recent)) return _approximate(recent);
      } catch (_) {
        // Missing cache or unsupported platforms still get a fresh lookup.
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 15),
        ),
      );
      if (!_usable(position)) {
        return const AreaLocationResult(MapArea.jakarta, 'locationUnavailable');
      }
      return _approximate(position);
    } on TimeoutException {
      return _failureAfterLookup('locationTimeout');
    } on LocationServiceDisabledException {
      return const AreaLocationResult(MapArea.jakarta, 'locationOff');
    } on PermissionDeniedException {
      return _failureAfterLookup('locationDenied');
    } catch (error) {
      if (kDebugMode) {
        // Diagnostics deliberately exclude coordinates and native messages.
        debugPrint('Area lookup failed: ${error.runtimeType}');
      }
      return _failureAfterLookup('locationUnavailable');
    }
  }

  bool _usable(Position position) {
    final age = DateTime.now().toUtc().difference(position.timestamp.toUtc());
    return age >= const Duration(seconds: -10) &&
        age <= const Duration(minutes: 1) &&
        position.latitude.isFinite &&
        position.longitude.isFinite &&
        position.accuracy.isFinite &&
        position.accuracy >= 0 &&
        position.accuracy <= 3000 &&
        position.latitude.abs() <= 85 &&
        position.longitude.abs() <= 180;
  }

  AreaLocationResult _approximate(Position position) {
    // Only this service sees the original fix. Never store, log, or upload it.
    final latitude = ((position.latitude / .02).round() * .02)
        .clamp(-85.0, 85.0)
        .toDouble();
    final longitude = ((position.longitude / .02).round() * .02)
        .clamp(-180.0, 180.0)
        .toDouble();
    return AreaLocationResult(
      MapArea(
        latitude,
        longitude,
        radius: math.max(2000.0, position.accuracy + 1600),
      ),
      'locationApproximate',
    );
  }

  Future<AreaLocationResult> _failureAfterLookup(String fallback) async {
    // Permission/services can change while a request is in progress.
    try {
      if (!await Geolocator.isLocationServiceEnabled().timeout(
        const Duration(seconds: 3),
      )) {
        return const AreaLocationResult(MapArea.jakarta, 'locationOff');
      }
      final permission = await Geolocator.checkPermission().timeout(
        const Duration(seconds: 3),
      );
      if (permission == LocationPermission.deniedForever) {
        return const AreaLocationResult(MapArea.jakarta, 'locationBlocked');
      }
      if (permission == LocationPermission.denied) {
        return const AreaLocationResult(MapArea.jakarta, 'locationDenied');
      }
    } catch (_) {
      // Preserve the original failure when even the status lookup is unavailable.
    }
    return AreaLocationResult(MapArea.jakarta, fallback);
  }
}
