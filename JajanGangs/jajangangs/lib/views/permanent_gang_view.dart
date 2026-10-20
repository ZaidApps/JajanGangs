import '../services/notification_sound.dart';
import '../controllers/permanent_gang_inbox_controller.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../controllers/permanent_gang_controller.dart';
import '../l10n/l10n.dart';
import '../models/auth_session.dart';
import '../models/user_profile.dart';
import '../services/permanent_gang_service.dart';
import '../widgets/adventure_header.dart';
import '../widgets/character_avatar.dart';
import '../widgets/game_dialog.dart';
import 'invite_friends_view.dart';

const _navy = Color(0xFF102C42),
    _gold = Color(0xFFFFCD61),
    _cream = Color(0xFFF1F6EC);
String _error(BuildContext context, Object e) =>
    context.l10n.message(e is AuthFailure ? e.message : 'pgError');
Future<bool> _confirm(
  BuildContext context,
  String title,
  String detail,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => GameDialog(
        title: Text(title),
        content: Text(detail),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.back),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(title),
          ),
        ],
      ),
    ) ==
    true;

class PermanentGangEditor extends StatefulWidget {
  const PermanentGangEditor({super.key, required this.uid, this.id, this.data});
  final String uid;
  final String? id;
  final Map<String, dynamic>? data;
  @override
  State<PermanentGangEditor> createState() => _PermanentGangEditorState();
}

class _PermanentGangEditorState extends State<PermanentGangEditor> {
  final service = PermanentGangService();
  late final id = widget.id ?? service.db.collection('gangs').doc().id;
  late final name = TextEditingController(text: widget.data?['name'] ?? '');
  late int capacity = widget.data?['capacity'] ?? 2;
  String avatar = AvatarCatalog.defaultId;
  bool busy = false;
  String? error;
  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      if (widget.id == null) {
        await service.create(id, widget.uid, name.text, avatar, capacity);
      } else {
        await service.manage(
          id,
          widget.uid,
          name: name.text,
          capacity: capacity,
        );
      }
      if (mounted) Navigator.pop(context, id);
    } catch (e) {
      if (mounted) setState(() => error = _error(context, e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        title: Text(
          widget.id == null ? context.l10n.pgCreate : context.l10n.pgManage,
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: FilledButton.icon(
            onPressed: busy ? null : save,
            icon: const Icon(Icons.groups_rounded),
            label: Text(
              busy
                  ? context.l10n.loading
                  : widget.id == null
                  ? context.l10n.pgCreate
                  : context.l10n.profileSave,
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AdventureHeader(
            title: context.l10n.pgTitle,
            subtitle: context.l10n.pgIntro,
            icon: Icons.groups_rounded,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: name,
            enabled: !busy,
            maxLength: 40,
            decoration: InputDecoration(labelText: context.l10n.pgName),
          ),
          if (widget.id == null) ...[
            const SizedBox(height: 16),
            AvatarPicker(
              initialValue: avatar,
              enabled: !busy,
              onChanged: (v) => avatar = v,
            ),
          ],
          const SizedBox(height: 24),
          Text(
            context.l10n.jajanPeopleQuestion,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
          ),
          Text(context.l10n.jajanIncludesCreator),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final n in [2, 3, 4, 5])
                ChoiceChip(
                  label: Text(n == 5 ? context.l10n.jajanFivePlus : '$n'),
                  selected: n == 5 ? capacity >= 5 : capacity == n,
                  selectedColor: _gold,
                  onSelected: busy
                      ? null
                      : (_) => setState(
                          () =>
                              capacity = n == 5 && capacity >= 5 ? capacity : n,
                        ),
                ),
            ],
          ),
          if (capacity >= 5)
            Row(
              children: [
                Expanded(
                  child: Text(context.l10n.jajanExactCapacity(capacity)),
                ),
                IconButton(
                  tooltip: context.l10n.jajanFewer,
                  onPressed: busy || capacity <= 5
                      ? null
                      : () => setState(() => capacity--),
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                IconButton(
                  tooltip: context.l10n.jajanMore,
                  onPressed: busy || capacity >= 12
                      ? null
                      : () => setState(() => capacity++),
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
          if (error != null)
            Text(error!, style: const TextStyle(color: Colors.red)),
        ],
      ),
    ),
  );
}

class PermanentGangListView extends StatefulWidget {
  const PermanentGangListView({super.key, required this.uid});
  final String uid;
  @override
  State<PermanentGangListView> createState() => _PermanentGangListViewState();
}

class _PermanentGangListViewState extends State<PermanentGangListView> {
  late final c = PermanentGangInboxController(widget.uid);
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
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (context, _) => ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AdventureHeader(
          title: context.l10n.pgTitle,
          subtitle: context.l10n.pgIntro,
          icon: Icons.groups_rounded,
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () async {
            final id = await Navigator.push<String>(
              context,
              MaterialPageRoute(
                builder: (_) => PermanentGangEditor(uid: widget.uid),
              ),
            );
            if (id != null && context.mounted)
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      PermanentGangChatView(id: id, uid: widget.uid),
                ),
              );
          },
          icon: const Icon(Icons.group_add_rounded),
          label: Text(context.l10n.pgCreate),
        ),
        const SizedBox(height: 12),
        Text(
          context.l10n.pgHiddenHint,
          style: const TextStyle(fontSize: 12, color: Color(0xFF526C76)),
        ),
        if (c.loading) const LinearProgressIndicator(),
        if (c.failed)
          TextButton(onPressed: c.start, child: Text(context.l10n.pgError)),
        if (!c.loading && !c.failed && c.items.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(context.l10n.pgEmpty),
          ),
        for (final doc in c.items)
          _PermanentRow(key: ValueKey(doc.id), doc: doc, uid: widget.uid),
        if (c.more)
          TextButton(
            onPressed: c.loading ? null : c.older,
            child: Text(context.l10n.chatMoreRooms),
          ),
      ],
    ),
  );
}

class _PermanentRow extends StatefulWidget {
  const _PermanentRow({super.key, required this.doc, required this.uid});
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final String uid;
  @override
  State<_PermanentRow> createState() => _PermanentRowState();
}

class _PermanentRowState extends State<_PermanentRow> {
  late final service = PermanentGangService();
  late final state = widget.doc.reference
      .collection('chat_state')
      .doc(widget.uid)
      .snapshots();
  Future<bool> hide() async {
    if (!await _confirm(
          context,
          context.l10n.chatDelete,
          context.l10n.chatDeleteHint,
        ) ||
        !mounted)
      return false;
    try {
      await service.cursor(
        widget.doc.id,
        widget.uid,
        widget.doc.data()['lastId'],
        hide: true,
      );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_error(context, e))));
    }
    return false;
  }

  @override
  Widget build(BuildContext context) => StreamBuilder(
    stream: state,
    builder: (context, s) {
      final d = widget.doc.data();
      final last = d['lastId'] as String;
      if (s.connectionState == ConnectionState.waiting)
        return const SizedBox.shrink();
      if (d['state'] == 'DELETING' && d['ownerId'] != widget.uid)
        return const SizedBox.shrink();
      if (d['state'] == 'ACTIVE' && s.data?.data()?['hiddenId'] == last)
        return const SizedBox.shrink();
      final unread =
          last.isNotEmpty &&
          d['lastSenderId'] != widget.uid &&
          s.data?.data()?['readId'] != last;
      return Dismissible(
        key: ValueKey(widget.doc.id),
        direction: d['state'] == 'ACTIVE'
            ? DismissDirection.endToStart
            : DismissDirection.none,
        confirmDismiss: (_) => hide(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.red.shade400,
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Icon(Icons.delete_outline, color: Colors.white),
        ),
        child: Card(
          color: unread ? const Color(0xFFE0F4EB) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CharacterAvatar(avatarId: d['avatarId'], size: 48),
            title: Text(
              d['name'],
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            subtitle: Text(
              d['state'] == 'DELETING'
                  ? context.l10n.pgDeleteRetry
                  : context.l10n.pgMembers(
                      (d['memberIds'] as List).length,
                      d['capacity'],
                    ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: unread
                ? Badge(
                    label: Text(context.l10n.chatUnread),
                    child: const Icon(Icons.chat_bubble_outline),
                  )
                : const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    PermanentGangChatView(id: widget.doc.id, uid: widget.uid),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class PermanentGangInvitationView extends StatefulWidget {
  const PermanentGangInvitationView({
    super.key,
    required this.id,
    required this.uid,
  });
  final String id, uid;
  @override
  State<PermanentGangInvitationView> createState() =>
      _PermanentGangInvitationViewState();
}

class _PermanentGangInvitationViewState
    extends State<PermanentGangInvitationView> {
  final service = PermanentGangService();
  late final gangDetails = service.gang(widget.id).get();
  bool busy = false;
  String? error;
  late final stream = service.inviteRef(widget.id, widget.uid).snapshots();
  Future<void> respond(bool accept) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await service.respond(widget.id, widget.uid, accept);
      if (!mounted) return;
      if (accept) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                PermanentGangChatView(id: widget.id, uid: widget.uid),
          ),
        );
      } else {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) setState(() => error = _error(context, e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _cream,
    appBar: AppBar(title: Text(context.l10n.pgInvite)),
    body: StreamBuilder(
      stream: stream,
      builder: (context, s) {
        final d = s.data?.data();
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            FutureBuilder(
              future: gangDetails,
              builder: (context, gangSnapshot) {
                final gang = gangSnapshot.data?.data();
                final people = gang?['members'] as Map? ?? {};
                final host = people[gang?['ownerId']] as Map?;
                final inviter = people[d?['inviterId']] as Map?;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AdventureHeader(
                      title:
                          gang?['name'] ??
                          d?['gangName'] ??
                          context.l10n.pgTitle,
                      subtitle: context.l10n.pgInviteHint,
                      icon: Icons.mail_outline_rounded,
                      leading: gang == null
                          ? null
                          : CharacterAvatar(
                              avatarId: gang['avatarId'],
                              size: 72,
                            ),
                    ),
                    if (host != null)
                      Card(
                        margin: const EdgeInsets.only(top: 16),
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              leading: CharacterAvatar(
                                avatarId: host['avatarId'],
                                size: 44,
                              ),
                              title: Text(
                                host['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              subtitle: Text(context.l10n.pgOwner),
                            ),
                            if (inviter != null &&
                                d?['inviterId'] != gang?['ownerId'])
                              ListTile(
                                leading: CharacterAvatar(
                                  avatarId: inviter['avatarId'],
                                  size: 44,
                                ),
                                title: Text(
                                  inviter['name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                subtitle: Text(context.l10n.pgInvitedBy),
                              ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            if (s.connectionState == ConnectionState.waiting)
              const LinearProgressIndicator(),
            if (s.hasError || s.hasData && d == null)
              Text(context.l10n.pgUnavailable),
            if (d?['status'] == 'REQUESTED') ...[
              FilledButton(
                onPressed: busy ? null : () => respond(true),
                child: Text(context.l10n.friendAccept),
              ),
              TextButton(
                onPressed: busy ? null : () => respond(false),
                child: Text(context.l10n.friendDecline),
              ),
            ] else if (d != null)
              Text(context.l10n.pgInviteHandled),
            if (busy) const LinearProgressIndicator(),
            if (error != null)
              Text(error!, style: const TextStyle(color: Colors.red)),
          ],
        );
      },
    ),
  );
}

class PermanentGangChatView extends StatefulWidget {
  const PermanentGangChatView({super.key, required this.id, required this.uid});
  final String id, uid;
  @override
  State<PermanentGangChatView> createState() => _PermanentGangChatViewState();
}

class _PermanentGangChatViewState extends State<PermanentGangChatView>
    with WidgetsBindingObserver {
  late final c = PermanentGangController(widget.id, widget.uid);
  final text = TextEditingController();
  bool busy = false;
  String? error;
  String read = '';
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    c.start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (NotificationSound.instance.activeChat == 'gang:${widget.id}')
      NotificationSound.instance.activeChat = null;
    c.dispose();
    text.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) setState(() {});
  }

  void markRead() {
    final visible =
        ModalRoute.of(context)?.isCurrent == true &&
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    if (visible && c.allowed) {
      NotificationSound.instance.activeChat = 'gang:${widget.id}';
    } else if (NotificationSound.instance.activeChat == 'gang:${widget.id}') {
      NotificationSound.instance.activeChat = null;
    }
    final last = c.data?['lastId'] as String? ?? '';
    if (!c.allowed ||
        last.isEmpty ||
        last == read ||
        ModalRoute.of(context)?.isCurrent != true ||
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed)
      return;
    read = last;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        await c.service.cursor(widget.id, widget.uid, last);
      } catch (_) {
        if (mounted) read = '';
      }
    });
  }

  Future<void> act(Future<void> Function() action, {bool close = false}) async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await action();
      if (close && mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => error = _error(context, e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> members() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: _cream,
      builder: (sheet) => SafeArea(
        child: ListenableBuilder(
          listenable: c,
          builder: (context, _) {
            final d = c.data;
            if (d == null || !c.allowed)
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Text(context.l10n.pgUnavailable),
              );
            final owner = d['ownerId'] == widget.uid;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.l10n.pgMembers(
                      (d['memberIds'] as List).length,
                      d['capacity'],
                    ),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  for (final uid in List<String>.from(d['memberIds']))
                    ListTile(
                      leading: CharacterAvatar(
                        avatarId: d['members'][uid]['avatarId'],
                        size: 40,
                      ),
                      title: Text(d['members'][uid]['name']),
                      subtitle: uid == d['ownerId']
                          ? Text(context.l10n.pgOwner)
                          : null,
                      trailing: owner && uid != widget.uid
                          ? PopupMenuButton<String>(
                              onSelected: (choice) async {
                                Navigator.pop(sheet);
                                final title = choice == 'transfer'
                                    ? context.l10n.pgTransfer
                                    : context.l10n.pgRemove;
                                if (!await _confirm(
                                      this.context,
                                      title,
                                      this.context.l10n.pgMemberConfirm,
                                    ) ||
                                    !mounted)
                                  return;
                                await act(
                                  () => c.service.manage(
                                    widget.id,
                                    widget.uid,
                                    newOwner: choice == 'transfer' ? uid : null,
                                    remove: choice == 'remove' ? uid : null,
                                  ),
                                );
                              },
                              itemBuilder: (_) => [
                                PopupMenuItem(
                                  value: 'transfer',
                                  child: Text(context.l10n.pgTransfer),
                                ),
                                PopupMenuItem(
                                  value: 'remove',
                                  child: Text(context.l10n.pgRemove),
                                ),
                              ],
                            )
                          : null,
                    ),
                  FilledButton.icon(
                    onPressed: () => Navigator.push(
                      sheet,
                      MaterialPageRoute(
                        builder: (_) => InviteFriendsView(
                          uid: widget.uid,
                          eventId: widget.id,
                          permanent: true,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.person_add_alt_1),
                    label: Text(context.l10n.inviteFriends),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> menu(String choice) async {
    if (choice == 'edit') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              PermanentGangEditor(uid: widget.uid, id: widget.id, data: c.data),
        ),
      );
      if (mounted) setState(() {});
      return;
    }
    if (choice == 'members') {
      await members();
      return;
    }
    final deleting = choice == 'delete';
    if (!await _confirm(
          context,
          deleting ? context.l10n.pgDelete : context.l10n.pgLeave,
          deleting ? context.l10n.pgDeleteHint : context.l10n.pgLeaveHint,
        ) ||
        !mounted)
      return;
    await act(
      () => deleting
          ? c.service.delete(widget.id, widget.uid)
          : c.service.manage(widget.id, widget.uid, remove: widget.uid),
      close: true,
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (context, _) {
      markRead();
      final d = c.data;
      final owner = d?['ownerId'] == widget.uid;
      final all = {...c.messages, ...c.pending}.entries.toList()
        ..sort(
          (a, b) => (b.value['createdAt'] as Timestamp? ?? Timestamp.now())
              .compareTo(a.value['createdAt'] as Timestamp? ?? Timestamp.now()),
        );
      return Scaffold(
        backgroundColor: _cream,
        appBar: AppBar(
          backgroundColor: _navy,
          foregroundColor: Colors.white,
          title: Text(d?['name'] ?? context.l10n.pgTitle),
          actions: [
            if (c.allowed)
              PopupMenuButton<String>(
                enabled: !busy,
                onSelected: menu,
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'members',
                    child: Text(context.l10n.pgMembersTitle),
                  ),
                  if (owner)
                    PopupMenuItem(
                      value: 'edit',
                      child: Text(context.l10n.pgManage),
                    ),
                  if (owner)
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(context.l10n.pgDelete),
                    )
                  else
                    PopupMenuItem(
                      value: 'leave',
                      child: Text(context.l10n.pgLeave),
                    ),
                ],
              ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              if (c.loading || busy) const LinearProgressIndicator(),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              if (c.failed)
                TextButton(
                  onPressed: c.start,
                  child: Text(context.l10n.chatLoadError),
                ),
              if (c.allowed)
                ListTile(
                  dense: true,
                  leading: CharacterAvatar(avatarId: d!['avatarId'], size: 36),
                  title: Text(
                    context.l10n.pgMembers(
                      (d['memberIds'] as List).length,
                      d['capacity'],
                    ),
                  ),
                  trailing: const Icon(Icons.people_alt_outlined),
                  onTap: members,
                ),
              if (!c.loading && !c.allowed)
                Expanded(
                  child: Center(
                    child: owner && d?['state'] == 'DELETING'
                        ? FilledButton(
                            onPressed: busy
                                ? null
                                : () => act(
                                    () =>
                                        c.service.delete(widget.id, widget.uid),
                                    close: true,
                                  ),
                            child: Text(context.l10n.pgDeleteRetry),
                          )
                        : Text(context.l10n.pgUnavailable),
                  ),
                ),
              if (c.allowed && all.isEmpty && !c.failed)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    context.l10n.chatEmptyHint,
                    textAlign: TextAlign.center,
                  ),
                ),
              if (c.allowed)
                Expanded(
                  child: ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: all.length + 1,
                    itemBuilder: (context, i) {
                      if (i == all.length)
                        return c.more
                            ? TextButton(
                                onPressed: c.paging ? null : c.older,
                                child: Text(context.l10n.eventLoadMore),
                              )
                            : const SizedBox.shrink();
                      final entry = all[i];
                      final m = entry.value;
                      final mine = m['senderId'] == widget.uid;
                      final failed = m['error'] != null;
                      final sending = m['sending'] == true;
                      final member =
                          (c.data?['members'] as Map?)?[m['senderId']] as Map?;
                      final avatar = Padding(
                        padding: const EdgeInsets.only(top: 2, bottom: 8),
                        child: Semantics(
                          label:
                              m['name'] as String? ??
                              member?['name'] as String? ??
                              context.l10n.foodie,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: mine
                                  ? const Color(0xFFFFE4A0)
                                  : const Color(0xFFDDEFE8),
                              shape: BoxShape.circle,
                            ),
                            child: CharacterAvatar(
                              avatarId:
                                  m['avatarId'] as String? ??
                                  member?['avatarId'] as String?,
                              size: 30,
                            ),
                          ),
                        ),
                      );
                      return Align(
                        alignment: mine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!mine) ...[avatar, const SizedBox(width: 7)],
                            Flexible(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.sizeOf(context).width * .72,
                                ),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: failed
                                        ? const Color(0xFFFFDAD6)
                                        : mine
                                        ? const Color(0xFFFFE4A0)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (!mine)
                                        Text(
                                          m['name'] ?? context.l10n.foodie,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF176F72),
                                          ),
                                        ),
                                      Text(m['text']),
                                      if (mine)
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (failed)
                                              TextButton(
                                                onPressed: () => c.send(
                                                  m['text'],
                                                  retryId: entry.key,
                                                ),
                                                child: Text(context.l10n.retry),
                                              )
                                            else
                                              Icon(
                                                sending
                                                    ? Icons.schedule
                                                    : Icons.check_rounded,
                                                size: 12,
                                                color: const Color(0xFF176F72),
                                              ),
                                            if (failed)
                                              Flexible(
                                                child: Text(
                                                  context.l10n.message(
                                                    m['error'],
                                                  ),
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (mine) ...[const SizedBox(width: 7), avatar],
                          ],
                        ),
                      );
                    },
                  ),
                ),
              if (c.allowed)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: text,
                          minLines: 1,
                          maxLines: 4,
                          maxLength: 1000,
                          decoration: InputDecoration(
                            hintText: context.l10n.pgMessage,
                            counterText: '',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        tooltip: context.l10n.pgSend,
                        onPressed: () {
                          final value = text.text.trim();
                          if (value.isEmpty) return;
                          text.clear();
                          unawaited(c.send(value));
                        },
                        icon: const Icon(Icons.send_rounded),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}
