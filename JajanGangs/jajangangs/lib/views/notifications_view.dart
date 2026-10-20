import 'permanent_gang_view.dart';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../controllers/activity_controller.dart';
import '../l10n/l10n.dart';
import '../models/home_map_state.dart';
import '../services/jajan_service.dart';
import 'event_details_view.dart';
import 'gang_chat_view.dart';
import 'friend_profile_view.dart';

String activityText(BuildContext context, String type) => switch (type) {
  'gang_invite' => context.l10n.pgInviteNotification,
  'gang_message' => context.l10n.pgMessageNotification,
  'event_invite' => context.l10n.inviteNotification,
  'accepted' => context.l10n.activityAccepted,
  'rejected' => context.l10n.activityRejected,
  _ => context.l10n.chatNewMessage,
};

Future<void> openActivity(
  BuildContext context,
  ActivityController controller,
  QueryDocumentSnapshot<Map<String, dynamic>> doc,
  MapArea area,
) async {
  if (FirebaseAuth.instance.currentUser?.uid != controller.uid) return;
  try {
    await controller.read(doc);
    if (!context.mounted) return;
    final data = doc.data();
    if (data['type'] == 'gang_invite' || data['type'] == 'gang_message') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => data['type'] == 'gang_invite'
              ? PermanentGangInvitationView(
                  id: data['gangId'] as String,
                  uid: controller.uid,
                )
              : PermanentGangChatView(
                  id: data['gangId'] as String,
                  uid: controller.uid,
                ),
        ),
      );
      return;
    }
    if (data['type'] == 'friend_request') {
      await showFriendProfile(
        context,
        peer: data['friendUid'] as String,
        name: data['actorName'] as String? ?? context.l10n.foodie,
      );
      return;
    }
    final id = data['eventId'] as String;
    if (data['type'] == 'message' || data['type'] == 'accepted') {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => GangChatView(eventId: id, uid: controller.uid),
        ),
      );
    } else {
      final snapshot = await FirebaseFirestore.instance
          .collection('jajan_events')
          .doc(id)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 15));
      final event = JajanService.decode(snapshot);
      if (!context.mounted) return;
      if (event == null || event.state == 'CANCELLING') {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.eventUnavailable)));
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EventDetailsView(
            openRequests:
                data['type'] == 'join_request' &&
                event.creatorId == controller.uid,
            marker: event.toMap(),
            area: area,
            uid: controller.uid,
          ),
        ),
      );
    }
  } catch (_) {
    if (context.mounted)
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.activityError)));
  }
}

class NotificationsView extends StatelessWidget {
  const NotificationsView({
    super.key,
    required this.controller,
    required this.area,
  });
  final ActivityController controller;
  final MapArea area;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF1F6EC),
    appBar: AppBar(title: Text(context.l10n.activityTitle)),
    body: ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(context.l10n.activityLimit),
          ),
          if (controller.loading) const LinearProgressIndicator(),
          if (controller.failed)
            Column(
              children: [
                Text(context.l10n.activityError),
                TextButton(
                  onPressed: controller.start,
                  child: Text(context.l10n.retry),
                ),
              ],
            ),
          if (!controller.loading &&
              !controller.failed &&
              controller.items.isEmpty)
            Expanded(child: Center(child: Text(context.l10n.activityEmpty))),
          if (controller.items.isNotEmpty)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: controller.items.length,
                itemBuilder: (context, index) {
                  final doc = controller.items[index];
                  final data = doc.data();
                  final read = controller.isRead(doc);
                  final stamp = (data['createdAt'] as Timestamp).toDate();
                  return Card(
                    color: read ? Colors.white : const Color(0xFFFFE6A3),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Icon(
                        data['type'] == 'friend_request'
                            ? Icons.person_add_alt_1_rounded
                            : data['type'] == 'message'
                            ? Icons.forum_rounded
                            : data['type'] == 'accepted'
                            ? Icons.celebration_rounded
                            : Icons.info_outline,
                      ),
                      title: Text(
                        data['type'] == 'friend_request'
                            ? context.l10n.friendNotification(
                                data['actorName'] as String? ??
                                    context.l10n.foodie,
                              )
                            : data['type'] == 'member_joined'
                            ? context.l10n.memberJoinedNotification(
                                data['requesterName'] as String? ??
                                    context.l10n.foodie,
                              )
                            : data['type'] == 'join_request'
                            ? context.l10n.activityJoinRequest(
                                data['requesterName'] as String? ??
                                    context.l10n.foodie,
                              )
                            : activityText(context, data['type'] as String),
                        style: TextStyle(
                          fontWeight: read
                              ? FontWeight.normal
                              : FontWeight.w800,
                        ),
                      ),
                      subtitle: Text(
                        DateFormat.MMMd(
                          Localizations.localeOf(context).languageCode,
                        ).add_Hm().format(stamp.toLocal()),
                      ),
                      trailing: read
                          ? null
                          : Semantics(
                              label: context.l10n.activityUnread,
                              child: const Icon(
                                Icons.circle,
                                size: 12,
                                color: Color(0xFF159F7B),
                              ),
                            ),
                      onTap: () => openActivity(context, controller, doc, area),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    ),
  );
}
