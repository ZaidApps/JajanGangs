import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

/// A brief branded handoff from the native launch screen. The real app starts
/// underneath immediately; no backend initialization is delayed by this view.
class BrandedLaunch extends StatefulWidget {
  const BrandedLaunch({super.key, required this.child});
  final Widget child;
  @override
  State<BrandedLaunch> createState() => _BrandedLaunchState();
}

class _BrandedLaunchState extends State<BrandedLaunch>
    with SingleTickerProviderStateMixin {
  late final animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  bool done = false, started = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (started) return;
    started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      done = true;
    } else {
      animation.forward().whenComplete(() {
        if (mounted) setState(() => done = true);
      });
    }
  }

  @override
  void dispose() {
    animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      ExcludeSemantics(excluding: !done, child: widget.child),
      if (!done)
        Positioned.fill(
          child: AbsorbPointer(
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, _) => Opacity(
                opacity:
                    1 -
                    const Interval(
                      .78,
                      1,
                      curve: Curves.easeOut,
                    ).transform(animation.value),
                child: Material(
                  color: const Color(0xFF102C42),
                  child: SafeArea(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final size = (constraints.maxHeight * .44).clamp(
                          100.0,
                          240.0,
                        );
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Transform.scale(
                                scale:
                                    .96 +
                                    .04 *
                                        Curves.easeOutBack.transform(
                                          animation.value,
                                        ),
                                child: Container(
                                  width: size,
                                  height: size,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        const Color(0xFF60D6BD)
                                            .withValues(alpha: .2),
                                        const Color(0xFF102C42),
                                      ],
                                    ),
                                  ),
                                  child: Image.asset(
                                    'assets/branding/mascot.png',
                                    semanticLabel: 'Jajan Gangs',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                child: Text(
                                  context.l10n.mapSlogan,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFFB5EFD8),
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
    ],
  );
}
