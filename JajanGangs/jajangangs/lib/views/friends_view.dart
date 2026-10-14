import 'package:flutter/material.dart';

import '../controllers/friends_controller.dart';
import '../l10n/l10n.dart';
import '../widgets/character_avatar.dart';
import 'friend_profile_view.dart';

class FriendsView extends StatelessWidget {
  const FriendsView({super.key, required this.uid});
  final String uid;
  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 3,
    child: Scaffold(
      backgroundColor: const Color(0xFFF1F6EC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF102C42),
        foregroundColor: Colors.white,
        title: Text(context.l10n.friendsTitle),
        bottom: TabBar(
          isScrollable: true,
          labelColor: const Color(0xFFFFC647),
          unselectedLabelColor: Colors.white70,
          indicatorColor: const Color(0xFFFFC647),
          tabs: [
            Tab(text: context.l10n.friendsTitle),
            Tab(text: context.l10n.friendIncoming),
            Tab(text: context.l10n.friendOutgoing),
          ],
        ),
      ),
      body: TabBarView(
        children: [
          for (final kind in ['friends', 'incoming', 'outgoing'])
            _FriendList(uid: uid, kind: kind),
        ],
      ),
    ),
  );
}

class _FriendList extends StatefulWidget {
  const _FriendList({required this.uid, required this.kind});
  final String uid, kind;
  @override
  State<_FriendList> createState() => _FriendListState();
}

class _FriendListState extends State<_FriendList>
    with AutomaticKeepAliveClientMixin {
  late final c = FriendsController(widget.uid, widget.kind);
  @override
  bool get wantKeepAlive => true;
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final l = context.l10n;
        final items = c.items;
        return Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: l.eventRefresh,
                onPressed: c.loading ? null : c.start,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ),
            if (c.loading) const LinearProgressIndicator(),
            if (c.failed)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Text(l.friendError),
                    TextButton(onPressed: c.start, child: Text(l.retry)),
                  ],
                ),
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (!c.loading && !c.failed && items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        widget.kind == 'friends'
                            ? l.friendsEmpty
                            : l.friendRequestsEmpty,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  for (final f in items)
                    Card(
                      color: widget.kind == 'incoming'
                          ? const Color(0xFFFFE6A3)
                          : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(
                          color: Color(0xFF102C42),
                          width: 1.5,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CharacterAvatar(
                          avatarId: f.avatar(c.uid),
                          size: 48,
                        ),
                        title: Text(
                          f.name(c.uid),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          widget.kind == 'friends'
                              ? l.friendConnected
                              : widget.kind == 'incoming'
                              ? l.friendIncomingHint
                              : l.friendPending,
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => showFriendProfile(
                          context,
                          peer: f.peer(c.uid),
                          name: f.name(c.uid),
                          avatar: f.avatar(c.uid),
                          eventId: f.data['sourceEventId'] as String?,
                        ),
                      ),
                    ),
                  if (c.more)
                    TextButton(
                      onPressed: c.loading ? null : c.older,
                      child: Text(l.eventLoadMore),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
