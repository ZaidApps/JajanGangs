import '../services/notification_sound.dart';

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/gang_message.dart';
import '../models/auth_session.dart';
import '../services/jajan_progress_service.dart';
import '../models/jajan_event.dart';
import '../services/gang_chat_service.dart';
import '../services/jajan_service.dart';

class GangChatController extends ChangeNotifier {
  GangChatController(this.id, this.uid);
  final String id, uid;
  final service = GangChatService();
  JajanEvent? event;
  bool loading = true, paging = false, hasMore = true, confirmed = false;
  String? error, sendError, memberError, progressError;
  bool progressing = false;
  final Map<String, GangMessage> _messages = {};
  List<Map<String, dynamic>> members = [];
  StreamSubscription? _eventSub, _messagesSub, _membersSub, _authSub;
  DocumentSnapshot<Map<String, dynamic>>? _oldest;
  Timer? _clock, _loadTimeout;
  bool _disposed = false;
  bool _restarting = false;
  bool visible = true;
  GangMessage? _newestConfirmed;
  Timer? _readTimer;
  bool get allowed =>
      event?.memberIds.contains(uid) == true && event?.state != 'CANCELLING';
  bool get canSend => allowed && confirmed && event!.isActive;
  List<GangMessage> get messages => _messages.values.toList()
    ..sort((a, b) {
      final time = (b.createdAt ?? DateTime(2100)).compareTo(
        a.createdAt ?? DateTime(2100),
      );
      return time != 0 ? time : b.id.compareTo(a.id);
    });
  void emit() {
    if (!_disposed) notifyListeners();
  }

  void start() {
    _clock = Timer.periodic(const Duration(seconds: 1), (_) => emit());
    _loadTimeout = Timer(const Duration(seconds: 15), () {
      if (loading) {
        error = 'chatLoadError';
        loading = false;
        emit();
      }
    });
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user?.uid != uid) {
        _revoke();
        emit();
      }
    });
    _eventSub = service
        .event(id)
        .snapshots(includeMetadataChanges: true)
        .listen(
          (doc) {
            if (_disposed || FirebaseAuth.instance.currentUser?.uid != uid)
              return;
            confirmed =
                !doc.metadata.isFromCache && !doc.metadata.hasPendingWrites;
            if (!confirmed) {
              emit();
              return;
            }
            event = JajanService.decode(doc);
            if (!allowed) {
              _revoke();
              emit();
              return;
            }
            if (_messagesSub == null) _listen();
            emit();
          },
          onError: (Object e) {
            _revoke();
            error = 'chatLoadError';
            emit();
          },
        );
  }

  Future<void> retry() async {
    if (_restarting || _disposed) return;
    _restarting = true;
    confirmed = false;
    await _eventSub?.cancel();
    await _messagesSub?.cancel();
    await _membersSub?.cancel();
    await _authSub?.cancel();
    if (_disposed) return;
    _messagesSub = null;
    _membersSub = null;
    _clock?.cancel();
    _loadTimeout?.cancel();
    loading = true;
    error = null;
    memberError = null;
    confirmed = false;
    start();
    _restarting = false;
    emit();
  }

  void _revoke() {
    confirmed = false;
    event = null;
    loading = false;
    error = 'chatClosed';
    _messages.clear();
    _oldest = null;
    hasMore = true;
    members = [];
    _messagesSub?.cancel();
    _messagesSub = null;
    _membersSub?.cancel();
    _membersSub = null;
  }

  void _listen() {
    _messagesSub = service
        .messages(id)
        .limit(30)
        .snapshots(includeMetadataChanges: true)
        .listen(
          (page) {
            if (_disposed || !allowed) return;
            for (final doc in page.docs) {
              final message = GangMessage(doc);
              // A cached/pending echo must not overwrite a failed local attempt.
              if (!doc.metadata.hasPendingWrites ||
                  !_messages.containsKey(doc.id)) {
                _messages[doc.id] = message;
              }
            }
            if (!page.metadata.isFromCache && page.docs.isNotEmpty) {
              final latest = GangMessage(page.docs.first);
              if (latest.timestamp != null &&
                  latest.delivery == MessageDelivery.sent) {
                _newestConfirmed = latest;
                _scheduleRead();
              }
            }
            _oldest ??= page.docs.lastOrNull;
            if (_oldest == null) hasMore = false;
            loading = false;
            error = null;
            _loadTimeout?.cancel();
            emit();
          },
          onError: (Object e) {
            loading = false;
            if (e is FirebaseException && e.code == 'permission-denied')
              _revoke();
            error = 'chatLoadError';
            emit();
          },
        );
    _membersSub = service
        .event(id)
        .collection('join_requests')
        .where('status', isEqualTo: 'ACCEPTED')
        .limit(12)
        .snapshots()
        .listen(
          (page) {
            if (_disposed || !allowed) return;
            members = page.docs.map((d) => d.data()).toList();
            memberError = null;
            emit();
          },
          onError: (Object e) {
            memberError = 'chatMembersError';
            emit();
          },
        );
  }

  Future<void> older() async {
    if (paging || !hasMore || _oldest == null || !allowed) return;
    paging = true;
    error = null;
    emit();
    try {
      final page = await service
          .messages(id)
          .startAfterDocument(_oldest!)
          .limit(30)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 15));
      if (_disposed || !allowed) return;
      for (final doc in page.docs) {
        _messages[doc.id] = GangMessage(doc);
      }
      if (page.docs.isNotEmpty) _oldest = page.docs.last;
      hasMore = page.docs.length == 30;
    } catch (_) {
      error = 'chatLoadError';
    } finally {
      paging = false;
      emit();
    }
  }

  bool send(String text) {
    if (!canSend) return false;
    if (text.trim().isEmpty || text.length > 1000) {
      sendError = 'chatInvalid';
      emit();
      return false;
    }
    sendError = null;
    final message = GangMessage.local(
      id: service.newId(id),
      senderId: uid,
      name: '',
      avatarId: 'cat',
      text: text.trim(),
      createdAt: DateTime.now(),
    );
    _messages[message.id] = message;
    emit();
    unawaited(_deliver(message));
    return true;
  }

  Future<void> retryMessage(GangMessage message) async {
    if (!canSend || message.delivery != MessageDelivery.failed) return;
    message.delivery = MessageDelivery.pending;
    emit();
    await _deliver(message);
  }

  Future<void> _deliver(GangMessage message) async {
    try {
      await service.send(id, uid, message.id, message.text);
      if (!_disposed && _messages.containsKey(message.id)) {
        _messages[message.id]!.delivery = MessageDelivery.sent;
      }
    } catch (e) {
      final current = _messages[message.id];
      // A late server snapshot can confirm a write whose Future timed out.
      if (current != null && current.delivery != MessageDelivery.sent) {
        current.delivery = MessageDelivery.failed;
      }
      if (kDebugMode) debugPrint('[GangChat] send: $e');
    } finally {
      emit();
    }
  }

  Future<void> advance(String target) async {
    if (progressing || !confirmed || event?.creatorId != uid) return;
    progressing = true;
    progressError = null;
    emit();
    try {
      await JajanProgressService().advance(id, uid, target);
    } catch (e) {
      progressError = e is AuthFailure ? e.message : 'eventStatusFailed';
      if (kDebugMode) debugPrint('[JajanProgress] $e');
    } finally {
      progressing = false;
      emit();
    }
  }

  void setVisible(bool value) {
    visible = value;
    final sound = NotificationSound.instance;
    if (value) {
      sound.activeChat = id;
    } else if (sound.activeChat == id) {
      sound.activeChat = null;
    }
    if (value) _scheduleRead();
  }

  void _scheduleRead() {
    _readTimer?.cancel();
    if (!visible || !allowed || _newestConfirmed == null) return;
    _readTimer = Timer(const Duration(milliseconds: 350), () async {
      if (_disposed || !visible || !allowed) return;
      try {
        await service.markRead(id, uid, _newestConfirmed!);
      } catch (e) {
        if (kDebugMode) debugPrint('[GangChat] mark read: $e');
      }
    });
  }

  @override
  void dispose() {
    if (NotificationSound.instance.activeChat == id)
      NotificationSound.instance.activeChat = null;
    _disposed = true;
    _clock?.cancel();
    _readTimer?.cancel();
    _loadTimeout?.cancel();
    _eventSub?.cancel();
    _messagesSub?.cancel();
    _membersSub?.cancel();
    _authSub?.cancel();
    super.dispose();
  }
}
