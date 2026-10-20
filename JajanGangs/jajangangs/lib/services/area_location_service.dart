import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

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
  // Keep only rounded coordinates with the ORIGINAL fix timestamp.
  // Reusing a fix must never extend its lifetime on each retry.
  static AreaLocationResult? _recentArea;
  static DateTime? _recentFixAt;
  static final _preferences = SharedPreferencesAsync();
  static bool _precisionOffered = false;
  static const _savedKey = 'rounded_area_v1';
  static const _maximumAge = Duration(minutes: 2);
  bool get _android =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
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
        // This prompt already offered both permissions. Do not immediately
        // ask again if the user deliberately chose Approximate.
        _precisionOffered = true;
        if (_android) {
          try {
            await _preferences
                .setBool('area_precision_offered_v1', true)
                .timeout(const Duration(seconds: 1));
          } catch (_) {}
        }
      }
      if (permission == LocationPermission.deniedForever) {
        return const AreaLocationResult(MapArea.jakarta, 'locationBlocked');
      }
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return const AreaLocationResult(MapArea.jakarta, 'locationDenied');
      }
      if (_recentArea != null &&
          _recentFixAt != null &&
          _fresh(_recentFixAt!)) {
        _diagnostic('memory-cache');
        return _recentArea!;
      }
      final saved = await _savedArea();
      if (saved != null) return saved;
      final cached = await _lastKnown();
      if (cached != null) return cached;
      await _offerPrecision();
      if (_android) {
        try {
          final accuracy = await Geolocator.getLocationAccuracy().timeout(
            const Duration(seconds: 1),
          );
          _diagnostic(
            accuracy == LocationAccuracyStatus.precise
                ? 'permission-precise'
                : 'permission-approximate',
          );
        } catch (_) {}
      }
      try {
        return _remember(await _firstUsable(forceManager: false));
      } on PermissionDeniedException {
        rethrow;
      } on LocationServiceDisabledException {
        rethrow;
      } catch (error) {
        _diagnostic('primary-provider', error);
        if (!_android) rethrow;
      }
      // Some Android devices stall in Google Play Services' fused provider.
      // Try the native provider only after the first subscription is cancelled.
      final nativeCached = await _lastKnown(forceManager: true);
      if (nativeCached != null) return nativeCached;
      try {
        return _remember(await _firstUsable(forceManager: true));
      } on TimeoutException {
        // A fix may have arrived in the OS cache while the provider was switching.
        final lateFix = await _lastKnown();
        if (lateFix != null) return lateFix;
        rethrow;
      }
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

  Future<void> _offerPrecision() async {
    if (!_android || _precisionOffered) return;
    _precisionOffered = true;
    try {
      final accuracy = await Geolocator.getLocationAccuracy().timeout(
        const Duration(seconds: 2),
      );
      if (accuracy == LocationAccuracyStatus.precise) return;
      if (await _preferences
              .getBool('area_precision_offered_v1')
              .timeout(const Duration(seconds: 1)) ==
          true)
        return;
      await _preferences
          .setBool('area_precision_offered_v1', true)
          .timeout(const Duration(seconds: 1));
      // Android offers Approximate / Precise. Respect either choice; never
      // request background access or repeatedly prompt on every lookup.
      _diagnostic('precision-permission-offer');
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw PermissionDeniedException('Location permission declined');
      }
    } on PermissionDeniedException {
      rethrow;
    } catch (error) {
      _diagnostic('precision-offer-unavailable', error);
    }
  }

  Future<void> _saveArea(MapArea area, DateTime timestamp) async {
    try {
      await _preferences
          .setString(
            _savedKey,
            jsonEncode({
              'lat': area.latitude,
              'lng': area.longitude,
              'radius': area.radius,
              'at': timestamp.millisecondsSinceEpoch,
            }),
          )
          .timeout(const Duration(seconds: 1));
    } catch (_) {
      /* Caching must never block location delivery. */
    }
  }

  Future<AreaLocationResult?> _savedArea() async {
    try {
      final value = await _preferences
          .getString(_savedKey)
          .timeout(const Duration(milliseconds: 400));
      if (value == null) return null;
      final d = jsonDecode(value) as Map<String, dynamic>;
      final timestamp = DateTime.fromMillisecondsSinceEpoch(
        d['at'] as int,
        isUtc: true,
      );
      final lat = (d['lat'] as num).toDouble(),
          lng = (d['lng'] as num).toDouble(),
          radius = (d['radius'] as num).toDouble();
      if (!_fresh(timestamp) ||
          !lat.isFinite ||
          !lng.isFinite ||
          !radius.isFinite ||
          lat.abs() > 85 ||
          lng.abs() > 180 ||
          radius < 2000 ||
          radius > 4600)
        return null;
      final result = AreaLocationResult(
        MapArea(
          (lat / .02).round() * .02,
          (lng / .02).round() * .02,
          radius: radius,
        ),
        'locationApproximate',
      );
      _recentArea = result;
      _recentFixAt = timestamp;
      _diagnostic('rounded-disk-cache');
      return result;
    } catch (_) {
      return null;
    }
  }

  bool _fresh(DateTime timestamp) {
    final age = DateTime.now().toUtc().difference(timestamp.toUtc());
    return age >= const Duration(seconds: -10) && age <= _maximumAge;
  }

  void _diagnostic(String stage, [Object? error]) {
    if (kDebugMode)
      debugPrint(
        '[AreaLocation] $stage${error == null ? '' : ': ${error.runtimeType}'}',
      );
  }

  Future<AreaLocationResult?> _lastKnown({bool forceManager = false}) async {
    try {
      final fix = await Geolocator.getLastKnownPosition(
        forceAndroidLocationManager: forceManager,
      ).timeout(const Duration(seconds: 1));
      if (fix != null && _usable(fix)) {
        _diagnostic(forceManager ? 'native-cache' : 'os-cache');
        return _remember(fix);
      }
    } catch (error) {
      _diagnostic('cache-unavailable', error);
    }
    return null;
  }

  Future<Position> _firstUsable({required bool forceManager}) async {
    final result = Completer<Position>();
    StreamSubscription<Position>? subscription;
    final budget = Duration(seconds: _android ? (forceManager ? 6 : 12) : 18);
    final rejected = <String>{};
    final timer = Timer(budget, () {
      if (!result.isCompleted)
        result.completeError(TimeoutException('Area lookup deadline'));
    });
    try {
      _diagnostic(forceManager ? 'native-start' : 'high-accuracy-start');
      final settings = _android
          ? AndroidSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 0,
              intervalDuration: const Duration(seconds: 1),
              forceLocationManager: forceManager,
            )
          : const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 0,
            );
      subscription = Geolocator.getPositionStream(locationSettings: settings)
          .listen(
            (position) {
              if (result.isCompleted) return;
              if (_usable(position)) {
                _diagnostic('usable-fix');
                result.complete(position);
              } else {
                final reason = !_fresh(position.timestamp)
                    ? 'sample-too-old'
                    : 'sample-invalid-or-inaccurate';
                if (rejected.add(reason)) _diagnostic(reason);
              }
            },
            onError: (Object error) {
              if (!result.isCompleted) result.completeError(error);
            },
            onDone: () {
              if (!result.isCompleted)
                result.completeError(StateError('Location stream ended'));
            },
          );
      // Ignore poor/old initial samples and wait for the first usable one.
      // The absolute deadline does not reset when unusable samples arrive.
      return await result.future;
    } finally {
      timer.cancel();
      await subscription?.cancel();
    }
  }

  AreaLocationResult _remember(Position position) {
    final result = _approximate(position);
    _recentArea = result;
    _recentFixAt = position.timestamp.toUtc();
    // Persist only the rounded cell, never the raw device coordinate.
    unawaited(_saveArea(result.area, _recentFixAt!));
    return result;
  }

  bool _usable(Position position) {
    return _fresh(position.timestamp) &&
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
