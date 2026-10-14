import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/home_map_state.dart';
import '../models/auth_session.dart';
import '../models/jajan_event.dart';
import '../services/area_location_service.dart';
import '../services/jajan_service.dart';
import '../services/jajan_cancellation_service.dart';

class HomeController extends ChangeNotifier {
  HomeController({required this.uid, AreaLocationService? location})
    : _location = location ?? AreaLocationService() {
    _expiryTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if ([..._owned, ..._nearby].any((e) => !e.isActive)) {
        _rebuild();
        if (!_disposed) notifyListeners();
      }
    });
  }
  final String uid;
  final AreaLocationService _location;
  final _service = JajanService();
  final _owned = <JajanEvent>[];
  final _nearby = <JajanEvent>[];
  bool _reloadRequested = false;
  Timer? _expiryTimer;
  MapArea area = MapArea.jakarta;
  List<MapJajan> events = [];
  String selectedId = '';
  String locationMessage = 'locationNeeded';
  String? eventsError;
  String? cancellationError;
  bool recoveringCancellations = false;
  bool loadingEvents = false;
  bool locating = false;
  bool _disposed = false;
  int cameraRevision = 0;
  MapJajan? get selected {
    for (final event in events) {
      if (event.id == selectedId) return event;
    }
    return null;
  }

  void _rebuild() {
    _owned.removeWhere((e) => !e.isActive);
    _nearby.removeWhere((e) => !e.isActive);
    final real = {
      for (final e in [..._nearby, ..._owned]) e.id: e,
    };
    events = real.values.map((e) => e.toMap()).toList();
    if (!events.any((e) => e.id == selectedId)) {
      selectedId = events.isEmpty ? '' : events.first.id;
    }
  }

  Future<void> loadEvents() async {
    if (_disposed) return;
    if (loadingEvents) {
      _reloadRequested = true;
      return;
    }
    final queryArea = area;
    loadingEvents = true;
    eventsError = null;
    notifyListeners();
    final knownIds = _owned.map((e) => e.id).toSet();
    try {
      final saved = await _service.loadOwn(uid);
      if (_disposed) return;
      // Keep a just-created event if this earlier query did not include it yet.
      final recent = _owned.where((e) => !knownIds.contains(e.id)).toList();
      final byId = {
        for (final e in saved) e.id: e,
        for (final e in recent) e.id: e,
      };
      _owned
        ..clear()
        ..addAll(byId.values);
      _rebuild();
      final nearby = await _service.loadNearby(uid, queryArea);
      if (_disposed) return;
      if (identical(area, queryArea)) {
        _nearby
          ..clear()
          ..addAll(nearby);
        _rebuild();
      }
    } catch (e) {
      eventsError = e is AuthFailure ? e.message : 'jajanLoadError';
    } finally {
      loadingEvents = false;
      if (!_disposed) {
        notifyListeners();
        if (_reloadRequested) {
          _reloadRequested = false;
          unawaited(loadEvents());
        }
      }
    }
  }

  Future<void> resumeCancellations() async {
    if (_disposed || recoveringCancellations) return;
    recoveringCancellations = true;
    cancellationError = null;
    notifyListeners();
    try {
      await JajanCancellationService().resume(uid);
    } catch (_) {
      cancellationError = 'eventCleanupPending';
    } finally {
      recoveringCancellations = false;
      if (!_disposed) {
        notifyListeners();
        await loadEvents();
      }
    }
  }

  void addCreated(JajanEvent event) {
    if (_disposed || !event.isActive) return;
    _owned.removeWhere((e) => e.id == event.id);
    _owned.insert(0, event);
    area = event.area;
    _nearby.clear();
    selectedId = event.id;
    locationMessage = 'locationApproximate';
    cameraRevision++;
    _rebuild();
    notifyListeners();
    unawaited(loadEvents());
  }

  Future<void> locate() async {
    if (locating || _disposed) return;
    locating = true;
    locationMessage = 'locationFinding';
    notifyListeners();
    final result = await _location.locate();
    if (_disposed) return;
    if (!result.area.isFallback) {
      area = result.area;
      _nearby.clear();
      _rebuild();
      cameraRevision++;
    }
    locationMessage = result.messageKey;
    locating = false;
    notifyListeners();
    if (!result.area.isFallback) unawaited(loadEvents());
  }

  void select(String id) {
    if (_disposed || !events.any((e) => e.id == id)) return;
    selectedId = id;
    notifyListeners();
  }

  void recenter() {
    if (!_disposed) {
      cameraRevision++;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _expiryTimer?.cancel();
    super.dispose();
  }
}
