import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/user_profile.dart';

Future<bool> showAvatarPreview(
  BuildContext context, {
  required String avatarId,
  required String name,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (_) => _AvatarPreviewDialog(avatarId: avatarId, name: name),
    ) ==
    true;

class _AvatarPreviewDialog extends StatelessWidget {
  const _AvatarPreviewDialog({required this.avatarId, required this.name});
  final String avatarId, name;
  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: const Color(0xFF182443),
    insetPadding: const EdgeInsets.all(20),
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 380,
        maxHeight: MediaQuery.sizeOf(context).height * .88,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.avatarPreviewTitle,
                    style: const TextStyle(
                      color: Color(0xFFD9CBFF),
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: () => Navigator.pop(context, false),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: AspectRatio(
                aspectRatio: 1,
                child: Semantics(
                  image: true,
                  label: name,
                  child: ExcludeSemantics(
                    child: _AnimatedPortrait(avatarId: avatarId),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 25,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.avatarPreviewHint,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFC5CDE0), height: 1.45),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFFCD61),
                  foregroundColor: const Color(0xFF182443),
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.check_circle_rounded),
                label: Text(context.l10n.avatarUseCharacter),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// Only the opened preview owns a ticker and loads the expression keyframe.
// Small avatars throughout the app continue to use the static CharacterAvatar.
class _AnimatedPortrait extends StatefulWidget {
  const _AnimatedPortrait({required this.avatarId});
  final String avatarId;
  @override
  State<_AnimatedPortrait> createState() => _AnimatedPortraitState();
}

class _AnimatedPortraitState extends State<_AnimatedPortrait>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final spec = _MotionSpec.forId(widget.avatarId);
  late final clock = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: spec.milliseconds),
  );
  late final open = ResizeImage(
    AssetImage(AvatarCatalog.asset(widget.avatarId)),
    width: 512,
    height: 512,
  );
  late final expression = ResizeImage(
    AssetImage(AvatarCatalog.motionAsset(widget.avatarId)),
    width: 512,
    height: 512,
  );
  bool _started = false, _ready = false, _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _prepare();
    }
    _syncMotion();
  }

  Future<void> _prepare() async {
    var failed = false;
    await Future.wait([
      precacheImage(open, context, onError: (error, stack) => failed = true),
      precacheImage(
        expression,
        context,
        onError: (error, stack) => failed = true,
      ),
    ]);
    if (!mounted) return;
    setState(() => _ready = !failed);
    _syncMotion();
  }

  void _syncMotion() {
    if (!mounted) return;
    final play =
        _ready &&
        _foreground &&
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.of(context) &&
        (ModalRoute.of(context)?.isCurrent ?? true);
    if (play) {
      if (!clock.isAnimating) clock.repeat();
    } else {
      clock.stop();
      clock.value = 0;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _syncMotion();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    clock.dispose();
    super.dispose();
  }

  Widget _image(ImageProvider provider) => Image(
    image: provider,
    fit: BoxFit.cover,
    gaplessPlayback: true,
    excludeFromSemantics: true,
    errorBuilder: (_, error, stack) => const ColoredBox(
      color: Color(0xFFDED3F8),
      child: Icon(Icons.person_rounded, color: Color(0xFF34305F)),
    ),
  );

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: ClipOval(
      child: AnimatedBuilder(
        animation: clock,
        builder: (context, _) {
          final t = clock.value;
          final wave = math.sin(t * math.pi * 2);
          final blink = spec.expression(t);
          return LayoutBuilder(
            builder: (context, bounds) {
              final scale = bounds.maxWidth / 512;
              return Stack(
                fit: StackFit.expand,
                children: [
                  _image(open),
                  if (_ready)
                    ClipPath(
                      clipper: const _PortraitInterior(),
                      child: Transform.translate(
                        offset: Offset(
                          spec.sway * wave * scale,
                          spec.nod * math.sin(t * math.pi * 4) * scale,
                        ),
                        child: Transform.rotate(
                          angle: spec.tilt * wave * math.pi / 180,
                          alignment: const Alignment(0, .1),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              _image(open),
                              Opacity(
                                opacity: blink,
                                child: _image(expression),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    ),
  );
}

class _PortraitInterior extends CustomClipper<Path> {
  const _PortraitInterior();
  @override
  Path getClip(Size size) => Path()
    ..addOval(
      Rect.fromCircle(
        center: Offset(size.width / 2, size.height / 2),
        radius: size.shortestSide * .43,
      ),
    );
  @override
  bool shouldReclip(_PortraitInterior oldClipper) => false;
}

class _MotionSpec {
  const _MotionSpec(
    this.milliseconds,
    this.tilt,
    this.nod,
    this.sway,
    this.at,
    this.hold, {
    this.again,
  });
  final int milliseconds;
  final double tilt, nod, sway, at, hold;
  final double? again;
  static _MotionSpec forId(String id) => switch (AvatarCatalog.displayId(id)) {
    'anime_02' => const _MotionSpec(3800, -1.6, 0, 0, .44, .045),
    'anime_03' => const _MotionSpec(4800, .3, 2, 0, .62, .015),
    'anime_04' => const _MotionSpec(5200, .5, .8, 0, .35, .01, again: .43),
    'anime_05' => const _MotionSpec(4400, 1.8, .5, 0, .4, .04),
    'anime_06' => const _MotionSpec(3600, -.6, 2.2, 0, .28, .045),
    'anime_07' => const _MotionSpec(5600, -1, 0, 0, .58, .03),
    'anime_08' => const _MotionSpec(4600, .5, 0, 1.4, .4, .01, again: .49),
    'anime_09' => const _MotionSpec(5000, -.9, 1, 0, .52, .05),
    'anime_10' => const _MotionSpec(5800, .35, 2.2, 0, .3, .015, again: .39),
    _ => const _MotionSpec(4000, .8, 0, 0, .3875, .0125),
  };

  double expression(double t) {
    double pulse(double center) {
      final distance = (t - center).abs();
      if (distance <= hold / 2) return 1;
      // Approximately 50 ms per eyelid transition, independent of loop length.
      return (1 - (distance - hold / 2) / (50 / milliseconds))
          .clamp(0.0, 1.0)
          .toDouble();
    }

    return math.max(pulse(at), again == null ? 0.0 : pulse(again!));
  }
}
