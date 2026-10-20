import 'game_dialog.dart';

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/food_wheel_controller.dart';
import '../models/food_wheel.dart';
import '../models/jajan_event.dart';
import '../l10n/l10n.dart';
import 'character_avatar.dart';

class FoodWheelCard extends StatefulWidget {
  const FoodWheelCard({
    super.key,
    required this.event,
    required this.uid,
    this.inline = false,
  });
  final JajanEvent event;
  final String uid;
  final bool inline;
  @override
  State<FoodWheelCard> createState() => _FoodWheelCardState();
}

class _FoodWheelCardState extends State<FoodWheelCard>
    with SingleTickerProviderStateMixin {
  late final c = FoodWheelController(widget.event.id, widget.uid);
  late final animation = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );
  final input = TextEditingController();
  String? seenRound;
  bool wasOpen = false;
  bool haptics = false;
  bool celebrate = false;
  double target = 0;
  int lastTick = -1;
  @override
  void initState() {
    super.initState();
    c.addListener(changed);
    c.start();
    animation.addListener(tick);
  }

  void tick() {
    final n = c.wheel?.uids.length ?? 0;
    final step = (angle * max(1, n) / (2 * pi)).floor();
    if (step != lastTick && animation.isAnimating) {
      lastTick = step;
      if (haptics && ModalRoute.of(context)?.isCurrent == true) {
        HapticFeedback.selectionClick();
      }
    }
  }

  double get angle => target * Curves.easeOutCubic.transform(animation.value);
  void changed() {
    final w = c.wheel;
    if (w == null) return;
    final same = seenRound == w.round;
    final shouldAnimate = same && wasOpen && w.closed;
    if (!same) {
      celebrate = false;
      animation.stop();
      input.text = w.choices.containsKey(widget.uid) ? w.food(widget.uid) : '';
      animation.value = 0;
      target = 0;
    }
    if (w.closed && (!same || wasOpen)) {
      final n = w.uids.length;
      final index = w.uids.indexOf(w.winner);
      target = 2 * pi * 6 + (2 * pi - (index + .5) * 2 * pi / n);
      if (shouldAnimate && !MediaQuery.disableAnimationsOf(context)) {
        celebrate = true;
        animation.forward(from: 0);
      } else {
        animation.value = 1;
      }
    }
    seenRound = w.round;
    wasOpen = !w.closed;
    if (w.choices.containsKey(widget.uid) && input.text != w.food(widget.uid)) {
      input.text = w.food(widget.uid);
    }
  }

  @override
  void dispose() {
    c.removeListener(changed);
    c.dispose();
    animation.dispose();
    input.dispose();
    super.dispose();
  }

  Future<void> history() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.sizeOf(context).height * .65,
        child: _WheelHistory(c: c),
      ),
    );
  }

  Future<void> createRound() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => GameDialog(
        icon: const Icon(Icons.casino_outlined),
        title: Text(context.l10n.dropWheelConfirm),
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
    if (mounted && yes == true)
      await c.act(() => c.service.create(c.eventId, c.uid));
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (context, _) {
      final l = context.l10n;
      final w = c.wheel;
      final enabled = widget.event.isActive && c.confirmed && !c.busy;
      if (widget.inline && w == null && c.error == null)
        return const SizedBox.shrink();
      final card = Card(
        color: const Color(0xFF102C42),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.wheelTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFFFC647),
                  fontWeight: FontWeight.w900,
                  fontSize: 23,
                ),
              ),
              if (c.loading || c.busy) const LinearProgressIndicator(),
              if (c.error != null)
                TextButton(
                  onPressed: c.busy ? null : c.start,
                  child: Text(
                    l.message(c.error!),
                    style: const TextStyle(color: Color(0xFFFFB8B8)),
                  ),
                ),
              if (w == null &&
                  !widget.inline &&
                  !c.loading &&
                  widget.event.isActive) ...[
                const SizedBox(height: 8),
                Text(
                  l.wheelHint,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
                FilledButton.icon(
                  onPressed: enabled ? createRound : null,
                  icon: const Icon(Icons.casino_rounded),
                  label: Text(l.wheelCreate),
                ),
              ],
              if (w != null) ...[
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    tooltip: l.wheelHaptics,
                    isSelected: haptics,
                    onPressed: () => setState(() => haptics = !haptics),
                    icon: Icon(
                      Icons.vibration,
                      color: haptics ? const Color(0xFFFFC647) : Colors.white54,
                    ),
                  ),
                ),
                Text(
                  l.wheelCreator(w.creatorName),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                AnimatedBuilder(
                  animation: animation,
                  builder: (context, _) => Column(
                    children: [
                      SizedBox(
                        height: 230,
                        width: 230,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Transform.rotate(
                              angle: angle,
                              child: CustomPaint(
                                size: const Size(220, 220),
                                painter: _WheelPainter(
                                  w.uids.map(w.food).toList(),
                                ),
                              ),
                            ),
                            const Positioned(
                              top: 0,
                              child: Icon(
                                Icons.arrow_drop_down_rounded,
                                size: 46,
                                color: Colors.white,
                              ),
                            ),
                            const CircleAvatar(
                              radius: 22,
                              backgroundColor: Color(0xFF102C42),
                              child: Icon(
                                Icons.restaurant,
                                color: Color(0xFFFFC647),
                              ),
                            ),
                            if (celebrate && animation.value > .75)
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: CustomPaint(
                                    painter: _Confetti(
                                      (animation.value - .75) / .25,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (w.closed)
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFC647),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                animation.isAnimating
                                    ? Icons.autorenew
                                    : Icons.celebration,
                                size: 30,
                              ),
                              Text(
                                animation.isAnimating
                                    ? l.wheelSpinning
                                    : l.wheelWinner(w.food(w.winner)),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                for (final uid in w.uids)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: CharacterAvatar(avatarId: w.avatar(uid), size: 32),
                    title: Text(
                      w.food(uid),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      w.name(uid),
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                if (!w.closed && widget.event.isActive) ...[
                  TextField(
                    controller: input,
                    enabled: enabled && !w.choices.containsKey(widget.uid),
                    maxLength: 40,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: l.wheelOption,
                      fillColor: const Color(0xFF24465C),
                      labelStyle: const TextStyle(color: Colors.white70),
                      counterStyle: const TextStyle(color: Colors.white70),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: enabled && !w.choices.containsKey(widget.uid)
                        ? () => c.act(
                            () => c.service.contribute(
                              c.eventId,
                              c.uid,
                              w.round,
                              input.text,
                            ),
                          )
                        : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFFC647),
                    ),
                    child: Text(
                      w.choices.containsKey(widget.uid)
                          ? l.wheelSubmitted
                          : l.wheelAdd,
                    ),
                  ),
                  Text(
                    w.uids.length < 2 ? l.wheelMinimum : l.wheelWait,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  if (w.creator == widget.uid ||
                      (widget.event.creatorId == widget.uid &&
                          !widget.event.memberIds.contains(w.creator)))
                    FilledButton.icon(
                      onPressed: enabled && w.uids.length >= 2
                          ? () => c.act(
                              () => c.service.spin(c.eventId, c.uid, w.round),
                            )
                          : null,
                      icon: const Icon(Icons.casino),
                      label: Text(l.wheelSpin),
                    ),
                ],
                if (w.closed && widget.event.isActive)
                  AnimatedBuilder(
                    animation: animation,
                    builder: (context, _) => TextButton(
                      onPressed: enabled && !animation.isAnimating
                          ? createRound
                          : null,
                      child: Text(
                        l.wheelNew,
                        style: const TextStyle(color: Color(0xFFFFC647)),
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 8),
              Text(
                l.wheelSuggestion,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              TextButton(
                onPressed: history,
                child: Text(
                  l.wheelHistory,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
      if (!widget.inline) return card;
      return Card(
        child: ExpansionTile(
          leading: const Icon(Icons.casino_rounded),
          title: Text(l.wheelTitle),
          subtitle: Text(
            w?.closed == true ? l.wheelWinner(w!.food(w.winner)) : l.wheelHint,
          ),
          children: [card],
        ),
      );
    },
  );
}

class _Confetti extends CustomPainter {
  _Confetti(this.progress);
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < 28; i++) {
      final a = i * 2 * pi / 28;
      final distance = (40 + 75 * progress) * (i.isEven ? 1 : .8);
      final point = Offset(
        size.width / 2 + cos(a) * distance,
        size.height / 2 + sin(a) * distance + 20 * progress * progress,
      );
      canvas.save();
      canvas.translate(point.dx, point.dy);
      canvas.rotate(a + progress * 4);
      canvas.drawRect(
        const Rect.fromLTWH(-3, -2, 6, 4),
        Paint()..color = _WheelPainter.colors[i % 6],
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _Confetti old) => old.progress != progress;
}

class _WheelHistory extends StatefulWidget {
  const _WheelHistory({required this.c});
  final FoodWheelController c;
  @override
  State<_WheelHistory> createState() => _WheelHistoryState();
}

class _WheelHistoryState extends State<_WheelHistory> {
  late var future = load();
  Future<List<FoodWheel>> load() async {
    final page = await widget.c.service
        .event(widget.c.eventId)
        .collection('wheel_history')
        .orderBy('createdAt', descending: true)
        .limit(10)
        .get()
        .timeout(const Duration(seconds: 15));
    return page.docs.map((d) => FoodWheel(d.data())).toList();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: future,
    builder: (context, snapshot) {
      if (snapshot.hasError)
        return Center(
          child: TextButton(
            onPressed: () => setState(() => future = load()),
            child: Text(context.l10n.retry),
          ),
        );
      if (!snapshot.hasData)
        return const Center(child: CircularProgressIndicator());
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            context.l10n.wheelHistory,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          if (snapshot.data!.isEmpty) Text(context.l10n.wheelEmpty),
          for (final w in snapshot.data!)
            ListTile(
              leading: const Icon(Icons.celebration),
              title: Text(context.l10n.wheelWinner(w.food(w.winner))),
              subtitle: Text(context.l10n.wheelCreator(w.creatorName)),
            ),
        ],
      );
    },
  );
}

class _WheelPainter extends CustomPainter {
  _WheelPainter(this.options);
  final List<String> options;
  static const colors = [
    Color(0xFFFFC647),
    Color(0xFF60D6BD),
    Color(0xFFFF8D99),
    Color(0xFFA6AEFF),
    Color(0xFFFFAE61),
    Color(0xFF8CD7EF),
  ];
  @override
  void paint(Canvas canvas, Size size) {
    final count = max(2, options.length), step = 2 * pi / count;
    final center = Offset(size.width / 2, size.height / 2),
        radius = size.width / 2;
    for (var i = 0; i < count; i++) {
      final start = -pi / 2 + i * step;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 3),
        start,
        step,
        true,
        Paint()..color = colors[i % colors.length],
      );
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 3),
        start,
        step,
        true,
        Paint()
          ..color = const Color(0xFF102C42)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      if (i < options.length) {
        final label = TextPainter(
          text: TextSpan(
            text: options[i],
            style: const TextStyle(
              color: Color(0xFF102C42),
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          textDirection: TextDirection.ltr,
          maxLines: 2,
          ellipsis: '…',
        )..layout(maxWidth: 65);
        final a = start + step / 2;
        label.paint(
          canvas,
          center +
              Offset(cos(a), sin(a)) * radius * .64 -
              Offset(label.width / 2, label.height / 2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WheelPainter old) =>
      old.options.join('\u0000') != options.join('\u0000');
}
