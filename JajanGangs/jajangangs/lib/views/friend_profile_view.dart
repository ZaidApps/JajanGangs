import '../widgets/game_dialog.dart';
import '../widgets/adventure_header.dart';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../controllers/friend_profile_controller.dart';
import '../l10n/l10n.dart';
import '../widgets/character_avatar.dart';
import 'food_passport_view.dart';
import 'report_user_view.dart';
import '../services/social_safety_service.dart';

Future<void> showFriendProfile(
  BuildContext context, {
  required String peer,
  required String name,
  String? avatar,
  String? eventId,
}) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null || uid == peer) return;
  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => FriendProfileView(
        uid: uid,
        peer: peer,
        name: name,
        avatar: avatar,
        eventId: eventId,
      ),
    ),
  );
}

class FriendProfileView extends StatefulWidget {
  const FriendProfileView({
    super.key,
    required this.uid,
    required this.peer,
    required this.name,
    this.avatar,
    this.eventId,
  });
  final String uid, peer, name;
  final String? avatar, eventId;
  @override
  State<FriendProfileView> createState() => _FriendProfileViewState();
}

class _FriendProfileViewState extends State<FriendProfileView> {
  late final c = FriendProfileController(widget.uid, widget.peer);
  @override
  void initState() {
    super.initState();
    c.start();
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  Future<void> remove() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => GameDialog(
        icon: const Icon(Icons.person_remove_outlined),
        title: Text(context.l10n.friendRemove),
        content: Text(context.l10n.friendRemoveHint),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.back),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.friendRemove),
          ),
        ],
      ),
    );
    if (mounted && yes == true)
      await c.act(() => c.service.change(c.uid, c.peer, 'REMOVED'));
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (context, _) {
      final l = context.l10n;
      final f = c.friendship;
      final enabled = c.confirmed && c.blocksReady && !c.blocked && !c.busy;
      final source = widget.eventId ?? f?.data['sourceEventId'] as String?;
      return Scaffold(
        backgroundColor: const Color(0xFFF1F6EC),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF1F6EC),
          foregroundColor: const Color(0xFF102C42),
          title: Text(l.friendProfile),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              AdventureHeader(
                title: f?.name(c.uid) ?? widget.name,
                subtitle: l.friendProfile,
                icon: Icons.person_rounded,
                leading: CharacterAvatar(
                  avatarId: f?.avatar(c.uid) ?? widget.avatar,
                  size: 72,
                ),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 0,
                margin: EdgeInsets.zero,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (c.loading || (c.busy && !c.sendingRequest))
                        const LinearProgressIndicator(),
                      if (c.error != null) ...[
                        Text(
                          l.message(c.error!),
                          style: const TextStyle(color: Colors.red),
                        ),
                        TextButton(
                          onPressed: c.busy ? null : c.start,
                          child: Text(l.retry),
                        ),
                      ],
                      if (c.blocked) ...[
                        Text(l.socialBlocked),
                      ] else if (c.optimisticSent) ...[
                        FilledButton.icon(
                          onPressed: null,
                          icon: const Icon(Icons.check_rounded),
                          label: Text(l.friendSent),
                        ),
                      ] else if (!c.loading && f?.status == 'ACCEPTED') ...[
                        FilledButton.icon(
                          onPressed: enabled
                              ? () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => FoodPassportView(
                                      ownerId: widget.peer,
                                      viewerId: widget.uid,
                                    ),
                                  ),
                                )
                              : null,
                          icon: const Icon(Icons.restaurant_menu_rounded),
                          label: Text(l.passportTitle),
                        ),
                        Text(
                          l.friendConnected,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: enabled ? remove : null,
                          icon: const Icon(Icons.person_remove_rounded),
                          label: Text(l.friendRemove),
                        ),
                      ] else if (!c.loading && f?.status == 'REQUESTED') ...[
                        if (f!.to != c.uid)
                          FilledButton.icon(
                            onPressed: null,
                            icon: const Icon(Icons.check_rounded),
                            label: Text(l.friendSent),
                          ),
                        Text(
                          f!.to == c.uid
                              ? l.friendIncomingHint
                              : l.friendPending,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        if (f.to == c.uid) ...[
                          FilledButton(
                            onPressed: enabled
                                ? () => c.act(
                                    () => c.service.change(
                                      c.uid,
                                      c.peer,
                                      'ACCEPTED',
                                    ),
                                  )
                                : null,
                            child: Text(l.friendAccept),
                          ),
                          TextButton(
                            onPressed: enabled
                                ? () => c.act(
                                    () => c.service.change(
                                      c.uid,
                                      c.peer,
                                      'DECLINED',
                                    ),
                                  )
                                : null,
                            child: Text(l.friendDecline),
                          ),
                        ] else
                          TextButton(
                            onPressed: enabled
                                ? () => c.act(
                                    () => c.service.change(
                                      c.uid,
                                      c.peer,
                                      'CANCELLED',
                                    ),
                                  )
                                : null,
                            child: Text(l.friendCancel),
                          ),
                      ] else if (!c.loading) ...[
                        if (f != null)
                          Text(
                            l.friendNotConnected,
                            textAlign: TextAlign.center,
                          ),
                        FilledButton.icon(
                          onPressed: enabled && source != null
                              ? () => c.send(source)
                              : null,
                          icon: const Icon(Icons.person_add_alt_1_rounded),
                          label: Text(l.friendAdd),
                        ),
                      ],
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.block_rounded),
                        label: Text(c.ownBlocked ? l.unblockUser : l.blockUser),
                        onPressed: !c.confirmed || !c.blocksReady || c.busy
                            ? null
                            : () async {
                                final yes = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => GameDialog(
                                    title: Text(
                                      c.ownBlocked
                                          ? l.unblockUser
                                          : l.blockUser,
                                    ),
                                    content: Text(
                                      c.ownBlocked
                                          ? l.unblockHint
                                          : l.blockHint,
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: Text(l.back),
                                      ),
                                      FilledButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: Text(
                                          c.ownBlocked
                                              ? l.unblockUser
                                              : l.blockUser,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                                if (!mounted || yes != true) return;
                                await c.act(
                                  () => c.ownBlocked
                                      ? SocialSafetyService().unblock(
                                          c.uid,
                                          c.peer,
                                        )
                                      : SocialSafetyService().block(
                                          c.uid,
                                          c.peer,
                                          widget.name,
                                        ),
                                );
                              },
                      ),
                      TextButton.icon(
                        onPressed: c.busy
                            ? null
                            : () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ReportUserView(
                                    uid: c.uid,
                                    peer: c.peer,
                                    eventId: source,
                                  ),
                                ),
                              ),
                        icon: const Icon(Icons.flag_outlined),
                        label: Text(l.reportUser),
                      ),
                      Text(
                        l.friendPrivacy,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
