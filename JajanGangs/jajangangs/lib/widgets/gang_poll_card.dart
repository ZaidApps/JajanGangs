import 'game_dialog.dart';

import 'package:flutter/material.dart';

import '../controllers/gang_poll_controller.dart';
import '../models/jajan_event.dart';
import '../l10n/l10n.dart';

Future<List<String>?> editGangPoll(BuildContext context) =>
    showDialog<List<String>>(
      context: context,
      builder: (_) => const _PollEditor(),
    );

class GangPollCard extends StatefulWidget {
  const GangPollCard({
    super.key,
    required this.event,
    required this.uid,
    this.inline = false,
  });
  final bool inline;
  final JajanEvent event;
  final String uid;
  @override
  State<GangPollCard> createState() => _GangPollCardState();
}

class _GangPollCardState extends State<GangPollCard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  late final c = GangPollController(widget.event.id, widget.uid);
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

  Future<void> create() async {
    final names = await showDialog<List<String>>(
      context: context,
      builder: (_) => const _PollEditor(),
    );
    if (!mounted || names == null) return;
    await c.run(() => c.service.create(c.id, c.uid, names));
  }

  Future<void> finish() async {
    final p = c.poll;
    if (p == null || p.leaders.isEmpty) return;
    final leaders = p.leaders;
    final winner = await showDialog<int>(
      context: context,
      builder: (context) => GameDialog(
        title: Text(
          leaders.length > 1 ? context.l10n.pollTie : context.l10n.pollFinish,
        ),
        scrollable: true,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.l10n.pollFinishHint),
            for (final i in leaders)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, i),
                  child: Text(p.options[i]),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.back),
          ),
        ],
      ),
    );
    if (!mounted || winner == null) return;
    await c.run(() => c.service.finish(c.id, c.uid, winner));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final l = context.l10n;
        final p = c.poll;
        final host = widget.event.creatorId == widget.uid;
        final enabled = widget.event.isActive && c.confirmed && !c.busy;
        if (p == null && widget.inline && c.error == null)
          return const SizedBox.shrink();
        if (p == null)
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (c.loading || c.busy) const LinearProgressIndicator(),
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
                if (!widget.inline &&
                    widget.event.memberIds.contains(widget.uid) &&
                    widget.event.state == 'OPEN' &&
                    !c.loading)
                  FilledButton.icon(
                    onPressed: enabled ? create : null,
                    icon: const Icon(Icons.how_to_vote_rounded),
                    label: Text(l.pollCreate),
                  ),
              ],
            ),
          );
        return Card(
          color: const Color(0xFFFFE6A3),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF102C42), width: 2),
          ),
          child: ExpansionTile(
            key: ValueKey(p?.closed),
            initiallyExpanded: !widget.inline,
            leading: Icon(
              p?.closed == true
                  ? Icons.emoji_events_rounded
                  : Icons.how_to_vote_rounded,
            ),
            title: Text(
              p?.closed == true ? l.pollDestination : l.pollTitle,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            subtitle: Text(
              p?.closed == true ? p!.options[p.winner] : l.pollSubtitle,
            ),
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Column(
                    children: [
                      if (c.loading || c.busy) const LinearProgressIndicator(),
                      if (c.error != null) ...[
                        Text(
                          l.message(c.error!),
                          style: const TextStyle(color: Colors.red),
                        ),
                        if (!c.confirmed)
                          TextButton(onPressed: c.start, child: Text(l.retry)),
                      ],
                      if (p != null) ...[
                        for (var i = 0; i < p.options.length; i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Material(
                              color: p.choice(widget.uid) == i
                                  ? const Color(0xFFB5EFD8)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap:
                                    enabled &&
                                        !p.closed &&
                                        widget.event.state == 'DECIDING'
                                    ? () => c.run(
                                        () => c.service.vote(c.id, c.uid, i),
                                      )
                                    : null,
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              p.options[i],
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          if (p.choice(widget.uid) == i)
                                            Icon(
                                              Icons.check_circle,
                                              semanticLabel: l.pollYourVote,
                                              color: const Color(0xFF159F7B),
                                            ),
                                          if (p.closed && p.winner == i)
                                            const Icon(
                                              Icons.emoji_events_rounded,
                                              color: Colors.orange,
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      LinearProgressIndicator(
                                        value: p.total == 0
                                            ? 0
                                            : p.buckets[i].length / p.total,
                                        minHeight: 8,
                                        color: const Color(0xFF159F7B),
                                        backgroundColor: const Color(
                                          0xFFE6EEE9,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      Text(l.pollVotes(p.buckets[i].length)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (!p.closed) ...[
                          Text(
                            widget.event.isActive ? l.pollTap : l.pollClosed,
                          ),
                          if (host)
                            FilledButton.icon(
                              onPressed: enabled && p.total > 0 ? finish : null,
                              icon: const Icon(Icons.flag_rounded),
                              label: Text(l.pollFinish),
                            ),
                          if (host && p.total == 0) Text(l.pollNoVotes),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PollEditor extends StatefulWidget {
  const _PollEditor();
  @override
  State<_PollEditor> createState() => _PollEditorState();
}

class _PollEditorState extends State<_PollEditor> {
  final fields = [TextEditingController(), TextEditingController()];
  bool invalid = false;
  @override
  void dispose() {
    for (final f in fields) {
      f.dispose();
    }
    super.dispose();
  }

  void submit() {
    final names = fields.map((f) => f.text.trim()).toList();
    if (names.any((n) => n.isEmpty || n.length > 60) ||
        names.map((n) => n.toLowerCase()).toSet().length != names.length) {
      setState(() => invalid = true);
      return;
    }
    Navigator.pop(context, names);
  }

  @override
  Widget build(BuildContext context) => GameDialog(
    icon: const Icon(Icons.how_to_vote_outlined),
    title: Text(context.l10n.pollCreate),
    content: SizedBox(
      width: 360,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.l10n.pollCreateHint),
            for (var i = 0; i < fields.length; i++)
              TextField(
                controller: fields[i],
                maxLength: 60,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: context.l10n.pollOption(i + 1),
                ),
              ),
            if (invalid)
              Text(
                context.l10n.pollInvalid,
                style: const TextStyle(color: Colors.red),
              ),
            if (fields.length < 5)
              TextButton.icon(
                onPressed: () =>
                    setState(() => fields.add(TextEditingController())),
                icon: const Icon(Icons.add),
                label: Text(context.l10n.pollAdd),
              ),
            if (fields.length > 2)
              TextButton(
                onPressed: () => setState(() => fields.removeLast().dispose()),
                child: Text(context.l10n.pollRemove),
              ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.l10n.back),
      ),
      FilledButton(onPressed: submit, child: Text(context.l10n.pollCreate)),
    ],
  );
}
