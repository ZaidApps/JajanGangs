import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/gang_poll_service.dart';
import '../services/food_wheel_service.dart';
import '../models/auth_session.dart';
import '../widgets/gang_poll_card.dart';
import '../widgets/food_wheel_card.dart';
import 'jajan_complete_view.dart';
import 'friend_profile_view.dart';

import 'package:flutter/material.dart';

import '../widgets/gang_message_bubble.dart';
import '../services/chat_route_observer.dart';

import '../controllers/gang_chat_controller.dart';
import '../l10n/l10n.dart';
import '../widgets/character_avatar.dart';

class GangChatView extends StatefulWidget {
  const GangChatView({super.key, required this.eventId, required this.uid});
  final String eventId, uid;
  @override
  State<GangChatView> createState() => _GangChatViewState();
}

class _GangChatViewState extends State<GangChatView>
    with WidgetsBindingObserver, RouteAware {
  late final c = GangChatController(widget.eventId, widget.uid);
  final text = TextEditingController();
  String? _lastEventState;
  static const ink = Color(0xFF102C42), gold = Color(0xFFFFC647);
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    c.setVisible(
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed,
    );
    c.addListener(_progressChanged);
    c.start();
  }

  @override
  void dispose() {
    chatRouteObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    c.removeListener(_progressChanged);
    c.dispose();
    text.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of<void>(context);
    if (route != null) chatRouteObserver.subscribe(this, route);
  }

  void _visibility(bool value) {
    c.setVisible(value);
  }

  @override
  void didPushNext() => _visibility(false);
  @override
  void didPopNext() => _visibility(
    WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed,
  );
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) => _visibility(
    state == AppLifecycleState.resumed &&
        ModalRoute.of(context)?.isCurrent == true,
  );
  void _progressChanged() {
    final state = c.event?.state;
    final justCompleted =
        state == 'COMPLETED' &&
        _lastEventState != null &&
        _lastEventState != state;
    if (state != null) _lastEventState = state;
    if (justCompleted && mounted && ModalRoute.of(context)?.isCurrent == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && c.event?.state == 'COMPLETED') _showCompletion();
      });
    }
  }

  void _showCompletion() {
    final event = c.event;
    if (event == null) return;
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => JajanCompleteView(event: event)));
  }

  bool _activityBusy = false;
  Future<void> dropActivity(String kind) async {
    if (_activityBusy || !c.allowed || c.event == null) return;
    setState(() => _activityBusy = true);
    try {
      final poll = GangPollService();
      final wheel = FoodWheelService();
      final snapshot =
          await (kind == 'wheel' ? wheel.current(c.id) : poll.poll(c.id))
              .get(const GetOptions(source: Source.server))
              .timeout(const Duration(seconds: 15));
      if (!mounted || !c.allowed) return;
      if (snapshot.exists &&
          (kind == 'vote' || snapshot.data()?['status'] == 'OPEN')) {
        await showActivity(kind);
        return;
      }
      if (!c.event!.isActive) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.chatClosed)));
        return;
      }
      final yes = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            kind == 'wheel'
                ? context.l10n.dropWheelConfirm
                : context.l10n.dropVoteConfirm,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.l10n.back),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.l10n.dropActivity),
            ),
          ],
        ),
      );
      if (!mounted || yes != true) return;
      if (kind == 'wheel') {
        await wheel.create(c.id, widget.uid);
      } else {
        final names = await editGangPoll(context);
        if (!mounted || names == null) return;
        await poll.create(c.id, widget.uid, names);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.message(
                e is AuthFailure
                    ? e.message
                    : kind == 'wheel'
                    ? 'wheelError'
                    : 'pollError',
              ),
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _activityBusy = false);
    }
  }

  Future<void> showActivity(String kind) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: SizedBox(
            height: MediaQuery.sizeOf(sheetContext).height * .72,
            child: ListenableBuilder(
              listenable: c,
              builder: (context, _) {
                if (!c.allowed || c.event == null)
                  return Center(child: Text(context.l10n.eventUnavailable));
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: kind == 'wheel'
                      ? FoodWheelCard(event: c.event!, uid: widget.uid)
                      : GangPollCard(event: c.event!, uid: widget.uid),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void send() {
    if (c.send(text.text)) text.clear();
  }

  void showMembers() => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => ListenableBuilder(
      listenable: c,
      builder: (context, _) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.l10n.chatMembers,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (c.event != null)
                ListTile(
                  leading: CharacterAvatar(
                    avatarId: c.event!.creatorAvatarId,
                    size: 46,
                  ),
                  onTap: c.event!.creatorId == widget.uid
                      ? null
                      : () => showFriendProfile(
                          context,
                          peer: c.event!.creatorId,
                          name: c.event!.creatorName ?? context.l10n.foodie,
                          avatar: c.event!.creatorAvatarId,
                          eventId: c.id,
                        ),
                  title: Text(c.event!.creatorName ?? context.l10n.foodie),
                  subtitle: Text(context.l10n.eventHost),
                ),
              if (c.memberError != null)
                Text(context.l10n.message(c.memberError!)),
              for (final m in c.members)
                ListTile(
                  leading: CharacterAvatar(
                    avatarId: m['avatarId'] as String?,
                    size: 46,
                  ),
                  onTap: m['userId'] == widget.uid
                      ? null
                      : () => showFriendProfile(
                          context,
                          peer: m['userId'] as String,
                          name: m['name'] as String? ?? context.l10n.foodie,
                          avatar: m['avatarId'] as String?,
                          eventId: c.id,
                        ),
                  title: Text(m['name'] as String? ?? context.l10n.foodie),
                ),
            ],
          ),
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (context, _) {
      final l = context.l10n;
      final items = c.messages;
      return Scaffold(
        backgroundColor: ink,
        appBar: AppBar(
          backgroundColor: ink,
          foregroundColor: Colors.white,
          title: Text(
            l.chatTitle,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Material(
                  color: gold,
                  borderRadius: BorderRadius.circular(22),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: c.allowed ? showMembers : null,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.restaurant_rounded,
                            size: 34,
                            color: ink,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l.chatSubtitle,
                                  style: const TextStyle(
                                    color: ink,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                  ),
                                ),
                                if (c.event?.state == 'ON_THE_WAY')
                                  Text(
                                    l.eventGoing,
                                    style: const TextStyle(
                                      color: ink,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                Text(
                                  c.event == null
                                      ? l.loading
                                      : l.jajanMemberCount(
                                          c.event!.memberCount,
                                          c.event!.capacity,
                                        ),
                                  style: const TextStyle(color: ink),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.groups_rounded, color: ink),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F6EC),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          l.chatTemporary,
                          style: const TextStyle(
                            color: Color(0xFF52716C),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (c.loading) const LinearProgressIndicator(),
                      if (c.error != null)
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              Text(
                                l.message(c.error!),
                                style: const TextStyle(color: Colors.red),
                              ),
                              TextButton(
                                onPressed: c.retry,
                                child: Text(l.retry),
                              ),
                            ],
                          ),
                        ),
                      Expanded(
                        child: ListView.builder(
                          reverse: true,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          itemCount: items.length + 2,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return c.allowed
                                  ? Column(
                                      children: [
                                        GangPollCard(
                                          key: ValueKey('poll:${c.id}'),
                                          event: c.event!,
                                          uid: widget.uid,
                                          inline: true,
                                        ),
                                        FoodWheelCard(
                                          key: ValueKey('wheel:${c.id}'),
                                          event: c.event!,
                                          uid: widget.uid,
                                          inline: true,
                                        ),
                                        if (c.progressError != null)
                                          Text(
                                            l.message(c.progressError!),
                                            style: const TextStyle(
                                              color: Colors.red,
                                            ),
                                          ),
                                        if (c.progressing)
                                          const LinearProgressIndicator(),
                                        if (c.event?.state == 'COMPLETED')
                                          FilledButton.icon(
                                            onPressed: _showCompletion,
                                            icon: const Icon(
                                              Icons.emoji_events_rounded,
                                            ),
                                            label: Text(l.eventCompleteTitle),
                                          ),
                                        if (c.event?.creatorId == widget.uid &&
                                            c.event!.isActive &&
                                            [
                                              'DESTINATION_SELECTED',
                                              'ON_THE_WAY',
                                            ].contains(c.event!.state))
                                          FilledButton.icon(
                                            onPressed:
                                                c.progressing || !c.confirmed
                                                ? null
                                                : () => c.advance(
                                                    c.event!.state == 'DESTINATION_SELECTED'
                                                        ? 'ON_THE_WAY'
                                                        : 'COMPLETED',
                                                  ),
                                            icon: Icon(
                                              c.event!.state ==
                                                      'DESTINATION_SELECTED'
                                                  ? Icons
                                                        .directions_walk_rounded
                                                  : Icons.celebration_rounded,
                                            ),
                                            label: Text(
                                              c.event!.state ==
                                                      'DESTINATION_SELECTED'
                                                  ? l.eventStartTrip
                                                  : l.eventCompleteAction,
                                            ),
                                          ),
                                      ],
                                    )
                                  : const SizedBox.shrink();
                            }
                            if (index == items.length + 1) {
                              if (!c.loading && c.allowed && items.isEmpty) {
                                return Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.forum_rounded,
                                        size: 48,
                                        color: ink,
                                      ),
                                      Text(
                                        l.chatEmpty,
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      Text(
                                        l.chatEmptyHint,
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                );
                              }
                              return c.hasMore && items.isNotEmpty
                                  ? Center(
                                      child: TextButton(
                                        onPressed: c.paging ? null : c.older,
                                        child: Text(
                                          c.paging ? l.loading : l.chatOlder,
                                        ),
                                      ),
                                    )
                                  : const SizedBox(height: 12);
                            }
                            final m = items[index - 1];
                            return GangMessageBubble(
                              key: ValueKey(m.id),
                              message: m,
                              mine: m.senderId == widget.uid,
                              onRetry: c.canSend
                                  ? () => c.retryMessage(m)
                                  : null,
                            );
                          },
                        ),
                      ),
                      if (c.sendError != null)
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            l.message(c.sendError!),
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      if (c.allowed && !c.event!.isActive)
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(l.chatClosed),
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: TextField(
                                controller: text,
                                enabled: c.canSend,
                                minLines: 1,
                                maxLines: 4,
                                maxLength: 1000,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                decoration: InputDecoration(
                                  hintText: l.chatHint,
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  counterText: '',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            PopupMenuButton<String>(
                              tooltip: l.chatActivities,
                              enabled: c.allowed && !_activityBusy,
                              icon: const Icon(
                                Icons.add_circle_outline_rounded,
                              ),
                              onSelected: dropActivity,
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'vote',
                                  child: ListTile(
                                    leading: const Icon(
                                      Icons.how_to_vote_rounded,
                                    ),
                                    title: Text(l.chatVoting),
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'wheel',
                                  child: ListTile(
                                    leading: const Icon(Icons.casino_rounded),
                                    title: Text(l.wheelTitle),
                                  ),
                                ),
                              ],
                            ),
                            IconButton.filled(
                              style: IconButton.styleFrom(
                                backgroundColor: gold,
                                foregroundColor: ink,
                                minimumSize: const Size(52, 52),
                              ),
                              tooltip: l.chatSend,
                              onPressed: c.canSend ? send : null,
                              icon: const Icon(Icons.send_rounded),
                            ),
                          ],
                        ),
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
