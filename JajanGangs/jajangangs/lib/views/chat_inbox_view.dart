import '../controllers/chat_inbox_controller.dart';
import '../models/jajan_event.dart';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../l10n/l10n.dart';
import '../services/jajan_service.dart';
import '../widgets/character_avatar.dart';
import 'gang_chat_view.dart';

class ChatInboxView extends StatefulWidget {
  const ChatInboxView({super.key, required this.uid});
  final String uid;
  @override
  State<ChatInboxView> createState() => _ChatInboxViewState();
}

class _ChatInboxViewState extends State<ChatInboxView> {
  late final c = ChatInboxController(widget.uid);
  @override
  void initState() {
    super.initState();
    c.listen();
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (context, _) {
      final l = context.l10n;
      final items = c.rooms.values.toList()
        ..sort(
          (a, b) => (b.data()!['createdAt'] as Timestamp? ?? Timestamp(0, 0))
              .compareTo(
                a.data()!['createdAt'] as Timestamp? ?? Timestamp(0, 0),
              ),
        );
      return Scaffold(
        backgroundColor: const Color(0xFFF1F6EC),
        appBar: AppBar(title: Text(l.chatInbox)),
        body: Column(
          children: [
            if (c.loading) const LinearProgressIndicator(),
            if (c.failed)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Text(l.chatLoadError),
                    TextButton(onPressed: c.listen, child: Text(l.retry)),
                  ],
                ),
              ),
            if (!c.loading && !c.failed && items.isEmpty)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(l.chatNoGangs, textAlign: TextAlign.center),
                  ),
                ),
              ),
            if (items.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length + 1,
                  itemBuilder: (context, i) {
                    if (i == items.length)
                      return c.more
                          ? TextButton(
                              onPressed: c.paging ? null : c.older,
                              child: Text(
                                c.paging ? l.loading : l.chatMoreRooms,
                              ),
                            )
                          : const SizedBox.shrink();
                    return _ChatRow(
                      key: ValueKey(items[i].id),
                      room: items[i],
                      uid: widget.uid,
                      onUnavailable: () => c.remove(items[i].id),
                    );
                  },
                ),
              ),
          ],
        ),
      );
    },
  );
}

class _ChatRow extends StatefulWidget {
  const _ChatRow({
    super.key,
    required this.room,
    required this.uid,
    required this.onUnavailable,
  });
  final VoidCallback onUnavailable;
  final DocumentSnapshot<Map<String, dynamic>> room;
  final String uid;
  @override
  State<_ChatRow> createState() => _ChatRowState();
}

class _ChatRowState extends State<_ChatRow> {
  late final room = widget.room.reference.snapshots();
  late final state = widget.room.reference
      .collection('chat_state')
      .doc(widget.uid)
      .snapshots();
  late final summary = widget.room.reference
      .collection('chat_summary')
      .doc('latest')
      .snapshots();
  late final legacyPreview = widget.room.reference
      .collection('messages')
      .orderBy('createdAt', descending: true)
      .limit(1)
      .get()
      .timeout(const Duration(seconds: 15));
  void removeLater() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) widget.onUnavailable();
  });
  @override
  Widget build(BuildContext context) => StreamBuilder(
    stream: room,
    initialData: widget.room,
    builder: (context, snapshot) {
      if (snapshot.hasError)
        return ListTile(title: Text(context.l10n.chatLoadError));
      final event = snapshot.data == null
          ? null
          : JajanService.decode(snapshot.data!);
      if (event == null ||
          event.state == 'CANCELLING' ||
          !event.memberIds.contains(widget.uid)) {
        if (snapshot.data?.metadata.isFromCache == false) removeLater();
        return const SizedBox.shrink();
      }
      return StreamBuilder(
        stream: state,
        builder: (context, cursor) => StreamBuilder(
          stream: summary,
          builder: (context, latest) {
            final d = <String, dynamic>{
              ...?latest.data?.data(),
              'readAt': cursor.data?.data()?['readAt'],
              'readId': cursor.data?.data()?['readId'],
            };
            final failed = cursor.hasError || latest.hasError;
            if (latest.connectionState == ConnectionState.waiting) {
              return tile(event, d, failed);
            }
            if (d['lastText'] == null && !failed) {
              return FutureBuilder(
                future: legacyPreview,
                builder: (context, old) {
                  final message = old.data?.docs.lastOrNull;
                  return tile(event, {
                    ...d,
                    if (message != null) ...{
                      'lastText': message.data()['text'],
                      'lastName': message.data()['name'],
                      'lastSenderId': message.data()['senderId'],
                      'lastMessageAt': message.data()['createdAt'],
                      'lastMessageId': message.id,
                    },
                  }, old.hasError);
                },
              );
            }
            return tile(event, d, failed);
          },
        ),
      );
    },
  );
  Widget tile(JajanEvent event, Map<String, dynamic> d, bool failed) {
    final l = context.l10n;
    final incoming = d['lastMessageAt'] as Timestamp?,
        read = d['readAt'] as Timestamp?;
    final unread =
        d['lastSenderId'] != widget.uid &&
        incoming != null &&
        (read == null ||
            incoming.compareTo(read) > 0 ||
            (incoming == read &&
                (d['lastMessageId'] as String? ?? '').compareTo(
                      d['readId'] as String? ?? '',
                    ) >
                    0));
    final at = (d['lastMessageAt'] as Timestamp?)?.toDate();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF102C42), width: 2),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CharacterAvatar(avatarId: event.creatorAvatarId, size: 48),
        title: Text(
          l.eventOwnerHungry(event.creatorName ?? l.foodie),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: unread ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
        subtitle: Text(
          failed
              ? l.chatLoadError
              : d['lastText'] != null
              ? l.chatPreview(
                  d['lastSenderId'] == widget.uid
                      ? l.chatYou
                      : d['lastName'] as String? ?? l.foodie,
                  d['lastText'] as String,
                )
              : event.isActive
              ? l.chatEmptyHint
              : l.eventExpired,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (at != null)
              Text(
                DateFormat.MMMd(Localizations.localeOf(context).languageCode)
                    .add_Hm()
                    .format(at.toLocal()),
                style: const TextStyle(fontSize: 10),
              ),
            if (unread)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Semantics(
                  label: l.chatUnread,
                  child: const Icon(
                    Icons.circle,
                    color: Color(0xFF159F7B),
                    size: 13,
                  ),
                ),
              ),
          ],
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GangChatView(eventId: event.id, uid: widget.uid),
          ),
        ),
      ),
    );
  }
}
