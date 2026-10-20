import '../widgets/jajan_schedule_badge.dart';
import 'permanent_gang_view.dart';
import '../widgets/game_dialog.dart';
import '../widgets/adventure_header.dart';
import '../controllers/chat_inbox_controller.dart';
import '../models/jajan_event.dart';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../l10n/l10n.dart';
import '../services/jajan_service.dart';
import '../services/gang_chat_service.dart';
import '../widgets/character_avatar.dart';
import 'gang_chat_view.dart';

class ChatInboxView extends StatelessWidget {
  const ChatInboxView({super.key, required this.uid});
  final String uid;
  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Scaffold(
      backgroundColor: const Color(0xFFF1F6EC),
      appBar: AppBar(
        title: Text(context.l10n.chatInbox),
        actions: [
          IconButton(
            tooltip: context.l10n.pgCreate,
            icon: const Icon(Icons.group_add_rounded),
            onPressed: () async {
              final id = await Navigator.push<String>(
                context,
                MaterialPageRoute(
                  builder: (_) => PermanentGangEditor(uid: uid),
                ),
              );
              if (id != null && context.mounted)
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PermanentGangChatView(id: id, uid: uid),
                  ),
                );
            },
          ),
        ],
        bottom: TabBar(
          tabs: [
            Tab(text: context.l10n.pgTemporary),
            Tab(text: context.l10n.pgTitle),
          ],
        ),
      ),
      body: TabBarView(
        children: [
          TemporaryChatsView(uid: uid),
          PermanentGangListView(uid: uid),
        ],
      ),
    ),
  );
}

class TemporaryChatsView extends StatefulWidget {
  const TemporaryChatsView({super.key, required this.uid});
  final String uid;
  @override
  State<TemporaryChatsView> createState() => _TemporaryChatsViewState();
}

class _TemporaryChatsViewState extends State<TemporaryChatsView> {
  late final c = ChatInboxController(widget.uid);
  final hidden = <String, bool>{};
  void visibilityChanged(String id, bool value) {
    if (hidden[id] == value) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && hidden[id] != value) setState(() => hidden[id] = value);
    });
  }

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
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: AdventureHeader(
                title: l.chatInbox,
                subtitle: l.chatInboxHint,
                icon: Icons.forum_rounded,
              ),
            ),
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
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                  children: [
                    if (items.every((item) => hidden[item.id] == true))
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          l.chatHiddenEmpty,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    // Keep hidden rows subscribed so a new message can restore them.
                    for (final item in items)
                      _ChatRow(
                        key: ValueKey(item.id),
                        room: item,
                        uid: widget.uid,
                        onHidden: (value) => visibilityChanged(item.id, value),
                        onUnavailable: () => c.remove(item.id),
                      ),
                  ],
                ),
              ),
            if (!c.loading && c.more)
              SafeArea(
                top: false,
                child: TextButton(
                  onPressed: c.paging ? null : c.older,
                  child: Text(c.paging ? l.loading : l.chatMoreRooms),
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
    required this.onHidden,
  });
  final VoidCallback onUnavailable;
  final ValueChanged<bool> onHidden;
  final DocumentSnapshot<Map<String, dynamic>> room;
  final String uid;
  @override
  State<_ChatRow> createState() => _ChatRowState();
}

class _ChatRowState extends State<_ChatRow> {
  String? pendingHiddenId;
  bool deleting = false;

  Future<void> hideChat(String lastId) async {
    final l = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => GameDialog(
        icon: const Icon(Icons.delete_outline_rounded),
        title: Text(l.chatDelete),
        content: Text(l.chatDeleteHint),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l.back),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l.chatDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || deleting) return;
    setState(() {
      pendingHiddenId = lastId;
      deleting = true;
    });
    try {
      await GangChatService().hideFromInbox(widget.room.id, widget.uid, lastId);
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.chatDeleteFailed)));
    } finally {
      if (mounted)
        setState(() {
          pendingHiddenId = null;
          deleting = false;
        });
    }
  }

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
          !event.isActive ||
          !event.memberIds.contains(widget.uid)) {
        if (event != null || snapshot.data?.metadata.isFromCache == false) {
          removeLater();
        }
        return const SizedBox.shrink();
      }
      return StreamBuilder(
        stream: state,
        builder: (context, cursor) => StreamBuilder(
          stream: summary,
          builder: (context, latest) {
            final d = <String, dynamic>{
              ...?latest.data?.data(),
              'hiddenMessageId': cursor.data?.data()?['hiddenMessageId'],
              'readAt': cursor.data?.data()?['readAt'],
              'readId': cursor.data?.data()?['readId'],
            };
            final failed = cursor.hasError || latest.hasError;
            if (!failed &&
                (latest.connectionState == ConnectionState.waiting ||
                    cursor.connectionState == ConnectionState.waiting)) {
              return const SizedBox.shrink();
            }
            if (d['lastText'] == null && !failed) {
              return FutureBuilder(
                future: legacyPreview,
                builder: (context, old) {
                  if (old.connectionState == ConnectionState.waiting)
                    return const SizedBox.shrink();
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
    final hiddenId = pendingHiddenId ?? (d['hiddenMessageId'] as String?);
    final isHidden =
        !failed &&
        hiddenId != null &&
        hiddenId == (d['lastMessageId'] as String? ?? '');
    widget.onHidden(isHidden);
    if (isHidden) return const SizedBox.shrink();
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
    return Dismissible(
      key: ValueKey('hide-${event.id}'),
      direction: deleting ? DismissDirection.none : DismissDirection.endToStart,
      confirmDismiss: (_) async {
        await hideChat(d['lastMessageId'] as String? ?? '');
        return false;
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(22),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: const Color(0xFFB44742),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Icon(Icons.delete_outline_rounded, color: Colors.white),
            const SizedBox(height: 4),
            Text(
              l.chatDelete,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 14),
        color: unread ? const Color(0xFFE8F6EF) : Colors.white,
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: unread ? const Color(0xFF159F7B) : const Color(0xFFDDE7E1),
            width: unread ? 2 : 1,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE2A0),
              borderRadius: BorderRadius.circular(20),
            ),
            child: CharacterAvatar(avatarId: event.creatorAvatarId, size: 44),
          ),
          title: Text(
            l.eventOwnerHungry(event.creatorName ?? l.foodie),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: unread ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              JajanScheduleBadge(time: event.scheduledAt, compact: true),
              const SizedBox(height: 5),
              Text(
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
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (unread)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.circle,
                          color: Color(0xFF159F7B),
                          size: 8,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l.chatUnread,
                          style: const TextStyle(
                            color: Color(0xFF147B60),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  if (at != null)
                    Text(
                      DateFormat.MMMd(
                        Localizations.localeOf(context).languageCode,
                      ).add_Hm().format(at.toLocal()),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF667C83),
                      ),
                    ),
                ],
              ),
            ],
          ),
          trailing: PopupMenuButton<String>(
            enabled: !deleting,
            icon: Icon(
              Icons.more_horiz_rounded,
              color: unread ? const Color(0xFF159F7B) : const Color(0xFF102C42),
            ),
            onSelected: (_) => hideChat(d['lastMessageId'] as String? ?? ''),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.delete_outline_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text(l.chatDelete),
                  ],
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
      ),
    );
  }
}
