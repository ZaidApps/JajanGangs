import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/permanent_gang_service.dart';

import 'package:flutter/material.dart';

import '../controllers/friends_controller.dart';
import '../l10n/l10n.dart';
import '../models/auth_session.dart';
import '../services/event_social_service.dart';
import '../widgets/character_avatar.dart';

class InviteFriendsView extends StatefulWidget {
  const InviteFriendsView({
    super.key,
    required this.uid,
    required this.eventId,
    this.permanent = false,
  });
  final String uid, eventId;
  final bool permanent;
  @override
  State<InviteFriendsView> createState() => _InviteFriendsViewState();
}

class _InviteFriendsViewState extends State<InviteFriendsView> {
  late final c = FriendsController(widget.uid, 'friends');
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? membership;
  Set<String> members = {};
  bool membersReady = false;
  bool membersFailed = false;
  bool activeMember = false;
  void watchMembers() {
    membership?.cancel();
    membersReady = false;
    membersFailed = false;
    membership = PermanentGangService()
        .gang(widget.eventId)
        .snapshots(includeMetadataChanges: true)
        .listen(
          (snapshot) {
            if (!mounted) return;
            final data = snapshot.data();
            setState(() {
              members = Set<String>.from(data?['memberIds'] as List? ?? []);
              activeMember =
                  data?['state'] == 'ACTIVE' && members.contains(widget.uid);
              membersReady = !snapshot.metadata.isFromCache;
              membersFailed = false;
              sent.removeWhere(members.contains);
            });
          },
          onError: (Object e) {
            if (mounted)
              setState(() {
                membersReady = false;
                membersFailed = true;
              });
          },
        );
  }

  final sent = <String>{};
  final pending = <String>{};
  final errors = <String, String>{};
  bool invitesReady = false;

  Future<void> restoreInvites() async {
    final saved = await EventSocialService().cachedInvites(
      widget.eventId,
      widget.uid,
    );
    if (!mounted) return;
    setState(() {
      sent.addAll(saved);
      invitesReady = true;
    });
  }

  @override
  void initState() {
    super.initState();
    c.start();
    if (!widget.permanent) unawaited(restoreInvites());
    if (widget.permanent) watchMembers();
  }

  @override
  void dispose() {
    membership?.cancel();
    c.dispose();
    super.dispose();
  }

  Future<void> invite(String peer) async {
    if (!widget.permanent && !invitesReady) return;
    if (widget.permanent &&
        (!membersReady || !activeMember || members.contains(peer)))
      return;
    if (pending.contains(peer) || sent.contains(peer)) return;
    setState(() {
      pending.add(peer);
      sent.add(peer);
      errors.remove(peer);
    });
    try {
      if (widget.permanent) {
        await PermanentGangService().invite(widget.eventId, widget.uid, peer);
      } else {
        await EventSocialService().invite(widget.eventId, widget.uid, peer);
      }
    } catch (e) {
      if (mounted)
        setState(() {
          sent.remove(peer);
          errors[peer] = e is AuthFailure ? e.message : 'inviteFailed';
        });
    } finally {
      if (mounted) setState(() => pending.remove(peer));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFFFAEF),
    appBar: AppBar(title: Text(context.l10n.inviteFriends)),
    body: ListenableBuilder(
      listenable: c,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            widget.permanent
                ? context.l10n.pgInviteFriendsHint
                : context.l10n.inviteHint,
          ),
          if (c.loading || widget.permanent && !membersReady && !membersFailed)
            const LinearProgressIndicator(),
          if (widget.permanent && membersFailed)
            TextButton(
              onPressed: () {
                setState(watchMembers);
              },
              child: Text(context.l10n.retry),
            ),
          if (widget.permanent && membersReady && !activeMember)
            Text(context.l10n.pgUnavailable),
          if (c.failed)
            TextButton(onPressed: c.start, child: Text(context.l10n.retry)),
          if (!c.loading && !c.failed && c.items.isEmpty)
            Text(context.l10n.inviteEmpty),
          for (final f in c.items)
            Card(
              child: ListTile(
                leading: CharacterAvatar(
                  avatarId: f.avatar(widget.uid),
                  size: 42,
                ),
                title: Text(f.name(widget.uid)),
                subtitle: errors.containsKey(f.peer(widget.uid))
                    ? Text(
                        context.l10n.message(errors[f.peer(widget.uid)]!),
                        style: const TextStyle(color: Colors.red),
                      )
                    : null,
                trailing: FilledButton.icon(
                  icon: Icon(
                    (members.contains(f.peer(widget.uid)) ||
                            sent.contains(f.peer(widget.uid)))
                        ? Icons.check_rounded
                        : Icons.person_add_alt_1_rounded,
                    size: 18,
                  ),
                  style: FilledButton.styleFrom(
                    disabledBackgroundColor: const Color(0xFFDDF2E9),
                    disabledForegroundColor: const Color(0xFF12664F),
                  ),
                  onPressed:
                      sent.contains(f.peer(widget.uid)) ||
                          !widget.permanent && !invitesReady ||
                          widget.permanent &&
                              (!membersReady ||
                                  !activeMember ||
                                  members.contains(f.peer(widget.uid)))
                      ? null
                      : () => invite(f.peer(widget.uid)),
                  label: Text(
                    widget.permanent && members.contains(f.peer(widget.uid))
                        ? context.l10n.pgAlreadyMember
                        : sent.contains(f.peer(widget.uid))
                        ? context.l10n.inviteSent
                        : context.l10n.inviteAction,
                  ),
                ),
              ),
            ),
          if (c.more)
            TextButton(
              onPressed: c.loading ? null : c.older,
              child: Text(context.l10n.socialLoadMore),
            ),
        ],
      ),
    ),
  );
}
