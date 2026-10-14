import '../services/jajan_progress_service.dart';

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/auth_session.dart';
import '../models/jajan_event.dart';
import '../services/event_details_service.dart';
import '../services/jajan_service.dart';
import '../services/jajan_cancellation_service.dart';

class EventDetailsController extends ChangeNotifier {
  EventDetailsController({required this.id, required this.uid});
  final String id;
  final String uid;
  final _service = EventDetailsService();
  JajanEvent? event;
  bool loading = true, busy = false, confirmed = false, requestLoaded = false;
  bool requestsLoading = false, hasMore = false, cancelling = false;
  String? requestStatus, decidingUid, actionError;
  bool cancellationStarted = false, cancellationComplete = false;
  bool _eventReadFailed = false,
      _requestReadFailed = false,
      _connectionExpired = false;
  int _requestsGeneration = 0;
  bool get sent => requestStatus != null;
  bool get canDecide =>
      confirmed &&
      isOwner &&
      !cancellationStarted &&
      !cancelling &&
      decidingUid == null &&
      event?.state == 'OPEN' &&
      (event?.isActive ?? false);
  int? requestCount;
  String? error, requestsError;
  final List<Map<String, dynamic>> pending = [];
  DocumentSnapshot<Map<String, dynamic>>? _cursor;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _eventSub,
      _requestSub;
  Timer? _timer;
  Timer? _connectionTimer;
  bool _disposed = false;
  int _generation = 0;
  bool get isOwner => event?.creatorId == uid;
  bool get isMember => event?.memberIds.contains(uid) ?? false;
  int get secondsLeft => event == null
      ? 0
      : event!.expiresAt
            .difference(DateTime.now().toUtc())
            .inSeconds
            .clamp(0, 2700);
  bool get canJoin =>
      confirmed &&
      requestLoaded &&
      !busy &&
      !sent &&
      !isOwner &&
      !isMember &&
      event != null &&
      event!.isActive &&
      event!.state == 'OPEN' &&
      secondsLeft > 0 &&
      event!.memberCount < event!.capacity;
  void _emit() {
    if (!_disposed) notifyListeners();
  }

  Future<void> start() async {
    final generation = ++_generation;
    await _eventSub?.cancel();
    await _requestSub?.cancel();
    if (_disposed || generation != _generation) return;
    loading = true;
    confirmed = false;
    requestLoaded = false;
    error = null;
    _eventReadFailed = false;
    _requestReadFailed = false;
    _connectionExpired = false;
    _connectionTimer?.cancel();
    _connectionTimer = null;
    _synchronizeReadState();
    _emit();
    _timer ??= Timer.periodic(const Duration(seconds: 1), (_) => _emit());
    _eventSub = _service
        .watchEvent(id)
        .listen(
          (snapshot) {
            if (_disposed || generation != _generation) return;
            confirmed =
                !snapshot.metadata.isFromCache &&
                !snapshot.metadata.hasPendingWrites;
            // A cache miss is not a server-confirmed missing event.
            if (confirmed || snapshot.exists)
              event = JajanService.decode(snapshot);
            if (confirmed) _eventReadFailed = false;
            _synchronizeReadState();
            if (confirmed &&
                isOwner &&
                event?.isPublic != true &&
                event?.state != 'CANCELLING' &&
                !cancellationStarted &&
                requestCount == null &&
                !requestsLoading) {
              unawaited(loadRequests());
            }
            _emit();
          },
          onError: (Object _) {
            if (_disposed || generation != _generation) return;
            confirmed = false;
            _eventReadFailed = true;
            _synchronizeReadState();
            _emit();
          },
        );
    _requestSub = _service
        .watchRequest(id, uid)
        .listen(
          (snapshot) {
            if (_disposed || generation != _generation) return;
            if (!snapshot.metadata.isFromCache &&
                !snapshot.metadata.hasPendingWrites) {
              requestLoaded = true;
              _requestReadFailed = false;
              requestStatus = snapshot.data()?['status'] as String?;
              if (requestStatus == 'PENDING') requestStatus = 'REQUESTED';
            } else {
              requestLoaded = false;
            }
            _synchronizeReadState();
            _emit();
          },
          onError: (Object _) {
            if (_disposed || generation != _generation) return;
            requestLoaded = false;
            _requestReadFailed = true;
            _synchronizeReadState();
            _emit();
          },
        );
  }

  void _synchronizeReadState() {
    if (cancellationStarted) {
      loading = false;
      error = null;
      _connectionTimer?.cancel();
      _connectionTimer = null;
      return;
    }
    final failed = _eventReadFailed || (_requestReadFailed && !isOwner);
    if (failed || (confirmed && event == null)) {
      loading = false;
      error = failed ? 'eventLoadError' : 'eventUnavailable';
      _connectionTimer?.cancel();
      _connectionTimer = null;
      return;
    }
    final waiting = !confirmed || (!isOwner && !requestLoaded);
    if (!waiting) {
      loading = false;
      error = null;
      _connectionExpired = false;
      _connectionTimer?.cancel();
      _connectionTimer = null;
      return;
    }
    loading = !_connectionExpired;
    error = _connectionExpired ? 'eventLoadError' : null;
    if (_connectionTimer == null && !_connectionExpired) {
      final generation = _generation;
      _connectionTimer = Timer(const Duration(seconds: 15), () {
        if (_disposed || generation != _generation) return;
        _connectionExpired = true;
        _synchronizeReadState();
        _emit();
      });
    }
  }

  Future<bool> join() async {
    if (!canJoin) return false;
    busy = true;
    actionError = null;
    _emit();
    try {
      final status = await _service.join(id, uid);
      requestStatus ??= status == 'PENDING' ? 'REQUESTED' : status;
      return status == 'ACCEPTED';
    } catch (e) {
      actionError = e is AuthFailure ? e.message : 'eventJoinError';
      return false;
    } finally {
      busy = false;
      _emit();
    }
  }

  Future<void> loadRequests({bool more = false}) async {
    if (!isOwner ||
        requestsLoading ||
        cancellationStarted ||
        event?.state == 'CANCELLING' ||
        cancelling ||
        _disposed ||
        (more && !hasMore))
      return;
    final requestGeneration = ++_requestsGeneration;
    requestsLoading = true;
    requestsError = null;
    _emit();
    try {
      final count = await _service.pendingCount(id);
      final page = await _service.pendingPage(id, more ? _cursor : null);
      if (_disposed || requestGeneration != _requestsGeneration) return;
      requestCount = count;
      if (!more) pending.clear();
      for (final doc in page.docs) {
        if (!pending.any((p) => p['userId'] == doc.id)) pending.add(doc.data());
      }
      _cursor = page.docs.isEmpty ? _cursor : page.docs.last;
      hasMore = page.docs.length == 20;
    } catch (_) {
      if (requestGeneration == _requestsGeneration && !_disposed)
        requestsError = 'eventRequestsError';
    } finally {
      if (requestGeneration == _requestsGeneration) {
        requestsLoading = false;
        _emit();
      }
    }
  }

  Future<void> decide(String requester, {required bool accept}) async {
    if (!canDecide || requestsLoading) return;
    decidingUid = requester;
    actionError = null;
    _emit();
    try {
      await _service.decide(id, uid, requester, accept: accept);
      pending.removeWhere((p) => p['userId'] == requester);
      if (requestCount != null && requestCount! > 0)
        requestCount = requestCount! - 1;
    } catch (e) {
      actionError = e is AuthFailure ? e.message : 'requestDecisionFailed';
    } finally {
      decidingUid = null;
      _emit();
      if (!_disposed) await loadRequests();
    }
  }

  bool progressing = false;
  Future<void> advance(String target) async {
    if (!isOwner || !confirmed || progressing || cancelling) return;
    progressing = true;
    actionError = null;
    _emit();
    try {
      await JajanProgressService().advance(id, uid, target);
    } catch (e) {
      actionError = e is AuthFailure ? e.message : 'eventStatusFailed';
    } finally {
      progressing = false;
      _emit();
    }
  }

  Future<bool> cancel() async {
    if ((!isOwner && !cancellationStarted) ||
        cancelling ||
        cancellationComplete ||
        decidingUid != null)
      return false;
    cancellationStarted = true;
    cancelling = true;
    _requestsGeneration++;
    requestsLoading = false;
    requestsError = null;
    actionError = null;
    _synchronizeReadState();
    _emit();
    try {
      await JajanCancellationService().cancel(id, uid);
      cancellationComplete = true;
      return true;
    } catch (failure) {
      actionError = failure is JajanCancellationFailure
          ? failure.messageKey
          : failure is AuthFailure
          ? failure.message
          : 'eventCancelFailed';
      return false;
    } finally {
      cancelling = false;
      _emit();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _timer?.cancel();
    _connectionTimer?.cancel();
    _eventSub?.cancel();
    _requestSub?.cancel();
    super.dispose();
  }
}
