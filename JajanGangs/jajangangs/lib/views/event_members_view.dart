import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'friend_profile_view.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../l10n/l10n.dart';
import '../services/jajan_service.dart';
import '../widgets/character_avatar.dart';

class EventMembersView extends StatefulWidget {
  const EventMembersView({super.key, required this.eventId});
  final String eventId;
  @override
  State<EventMembersView> createState() => _EventMembersViewState();
}

class _EventMembersViewState extends State<EventMembersView> {
  late final ref = FirebaseFirestore.instance
      .collection('jajan_events')
      .doc(widget.eventId);
  late var room = ref.snapshots();
  late var members = ref
      .collection('join_requests')
      .where('status', isEqualTo: 'ACCEPTED')
      .limit(12)
      .snapshots();
  Widget memberCard(
    String uid,
    String name,
    String? avatar, {
    bool host = false,
  }) => Card(
    color: host ? const Color(0xFFFFE6A3) : Colors.white,
    margin: const EdgeInsets.only(bottom: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: Color(0xFF102C42), width: 1.5),
    ),
    child: ListTile(
      onTap: uid == FirebaseAuth.instance.currentUser?.uid
          ? null
          : () => showFriendProfile(
              context,
              peer: uid,
              name: name,
              avatar: avatar,
              eventId: widget.eventId,
            ),
      trailing: uid == FirebaseAuth.instance.currentUser?.uid
          ? null
          : const Icon(Icons.chevron_right_rounded),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      leading: CharacterAvatar(avatarId: avatar, size: 48),
      title: Text(
        name,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Color(0xFF102C42),
        ),
      ),
      subtitle: host
          ? Text(
              context.l10n.eventHost,
              style: const TextStyle(color: Color(0xFF102C42)),
            )
          : null,
    ),
  );
  Widget failure() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(context.l10n.chatMembersError),
        TextButton(
          onPressed: () => setState(() {
            room = ref.snapshots();
            members = ref
                .collection('join_requests')
                .where('status', isEqualTo: 'ACCEPTED')
                .limit(12)
                .snapshots();
          }),
          child: Text(context.l10n.retry),
        ),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF1F6EC),
    appBar: AppBar(
      backgroundColor: const Color(0xFF102C42),
      foregroundColor: Colors.white,
      title: Text(context.l10n.chatMembers),
    ),
    body: StreamBuilder(
      stream: room,
      builder: (context, snapshot) {
        if (snapshot.hasError) return failure();
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final e = JajanService.decode(snapshot.data!);
        if (e == null || e.state == 'CANCELLING')
          return Center(child: Text(context.l10n.eventUnavailable));
        return StreamBuilder(
          stream: members,
          builder: (context, snapshot) => ListView(
            padding: const EdgeInsets.all(20),
            children: [
              memberCard(
                e.creatorId,
                e.creatorName ?? context.l10n.foodie,
                e.creatorAvatarId,
                host: true,
              ),
              if (snapshot.hasError)
                failure()
              else if (!snapshot.hasData)
                const LinearProgressIndicator()
              else
                for (final doc in snapshot.data!.docs)
                  memberCard(
                    doc.id,
                    doc.data()['name'] as String? ?? context.l10n.foodie,
                    doc.data()['avatarId'] as String?,
                  ),
            ],
          ),
        );
      },
    ),
  );
}
