import 'package:flutter/foundation.dart';

import '../models/auth_session.dart';
import '../models/home_map_state.dart';
import '../models/jajan_event.dart';
import '../services/area_location_service.dart';
import '../services/jajan_service.dart';

class CreateJajanController extends ChangeNotifier {
  CreateJajanController({
    required this.uid,
    required this.area,
    JajanService? service,
  }) : _service = service ?? JajanService();
  final String uid;
  final JajanService _service;
  MapArea area;
  Craving craving = Craving.anything;
  int capacity = 2;
  String description = '';
  String joinPolicy = 'public';
  DateTime? scheduledAt;
  void chooseSchedule(DateTime? value) {
    if (locked) return;
    scheduledAt = value?.toUtc();
    error = null;
    _emit();
  }

  void choosePolicy(String value) {
    if (!locked && ['public', 'private'].contains(value)) {
      joinPolicy = value;
      _emit();
    }
  }

  bool busy = false;
  bool restoring = true;
  bool locating = false;
  bool _disposed = false;
  JajanDraft? pending;
  String? error;
  bool get locked => busy || restoring || locating || pending != null;
  void _emit() {
    if (!_disposed) notifyListeners();
  }

  Future<void> restore() async {
    restoring = true;
    error = null;
    _emit();
    try {
      pending = await _service.restoreDraft(uid);
      if (pending != null) {
        scheduledAt = pending!.scheduledAt;
        description = pending!.description;
        joinPolicy = pending!.joinPolicy;
        craving = pending!.craving;
        capacity = pending!.capacity;
        area = pending!.area;
      }
    } catch (e) {
      error = e is AuthFailure ? e.message : 'jajanDraftError';
    }
    restoring = false;
    _emit();
  }

  void chooseCraving(Craving value) {
    if (!locked) {
      craving = value;
      _emit();
    }
  }

  void chooseCapacity(int value) {
    if (!locked) {
      capacity = value.clamp(2, 12);
      _emit();
    }
  }

  Future<JajanEvent?> submit() async {
    if (busy ||
        restoring ||
        locating ||
        _disposed ||
        error == 'jajanDraftError')
      return null;
    if (description.trim().runes.length > 150) {
      error = 'descriptionTooLong';
      _emit();
      return null;
    }
    busy = true;
    error = null;
    _emit();
    try {
      // An unresolved write must reuse its original location and event ID.
      if (pending == null) {
        JajanService.validateSchedule(scheduledAt);
        await _service.ensureCanCreate(uid);
        if (_disposed) return null;
        locating = true;
        _emit();
        final result = await AreaLocationService().locate();
        if (_disposed) return null;
        locating = false;
        if (result.area.isFallback) {
          error = switch (result.messageKey) {
            'locationOff' => 'jajanLocationOff',
            'locationBlocked' => 'jajanLocationBlocked',
            'locationDenied' => 'jajanLocationDenied',
            'locationTimeout' => 'jajanLocationTimeout',
            _ => 'jajanLocationUnavailable',
          };
          return null;
        }
        area = result.area;
        _emit();
      }
      pending ??= await _service.prepare(
        uid,
        craving,
        capacity,
        area,
        scheduledAt: scheduledAt,
        description: description,
        joinPolicy: joinPolicy,
      );
      if (_disposed) return null;
      final event = await _service.create(uid, pending!);
      pending = null;
      return event;
    } catch (e) {
      error = e is AuthFailure ? e.message : 'jajanSaveError';
      if (error == 'jajanScheduleInvalid') pending = null;
      return null;
    } finally {
      locating = false;
      busy = false;
      _emit();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
