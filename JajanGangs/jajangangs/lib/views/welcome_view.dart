import '../widgets/language_selector.dart';
import '../l10n/l10n.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/welcome_game_elements.dart';

class WelcomeView extends StatefulWidget {
  const WelcomeView({super.key, this.onGetStarted, this.onLogin});
  final VoidCallback? onGetStarted;
  final VoidCallback? onLogin;
  @override
  State<WelcomeView> createState() => _WelcomeViewState();
}

class _WelcomeViewState extends State<WelcomeView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: Duration(seconds: 3),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _float.stop();
      _float.value = 0;
    } else {
      _float.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light.copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: WelcomePalette.navy,
    ),
    child: Scaffold(
      backgroundColor: WelcomePalette.navy,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: ExcludeSemantics(
              child: Image(
                image: AssetImage('assets/images/welcome_city.png'),
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x80051C30),
                    Color(0x26051C30),
                    Color(0x40051C30),
                    Color(0xF2051C30),
                  ],
                  stops: [0, .34, .6, 1],
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final scale = MediaQuery.textScalerOf(context).scale(1);
                final minHeight = scale > 1.35 ? 990.0 : 750.0;
                final height = math.max(constraints.maxHeight, minHeight);
                return SingleChildScrollView(
                  child: Center(
                    child: SizedBox(
                      width: math.min(constraints.maxWidth, 520),
                      height: scale > 1.35 ? null : height,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(24, 22, 24, 20),
                        child: Column(
                          children: [
                            const Align(
                              alignment: Alignment.centerRight,
                              child: LanguageSelector(),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(height: 185, child: GameLogo()),
                            SizedBox(height: 14),
                            Text(
                              context.l10n.tagline,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                fontStyle: FontStyle.italic,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: WelcomePalette.navy,
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                            ),
                            _SceneSpace(
                              expand: scale <= 1.35,
                              child: ExcludeSemantics(
                                child: AnimatedBuilder(
                                  animation: _float,
                                  builder: (context, _) => LayoutBuilder(
                                    builder: (context, area) {
                                      Widget pin(
                                        double x,
                                        double y,
                                        double size,
                                        Color color,
                                        IconData icon,
                                        double phase,
                                      ) => Positioned(
                                        left: (area.maxWidth - size) * x,
                                        top: math.max(
                                          0,
                                          (area.maxHeight - size * 1.48) * y +
                                              math.sin(
                                                    (_float.value + phase) *
                                                        math.pi,
                                                  ) *
                                                  5,
                                        ),
                                        child: FoodPin(
                                          size: size,
                                          color: color,
                                          icon: icon,
                                        ),
                                      );
                                      return Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          pin(
                                            .02,
                                            .12,
                                            54,
                                            Color(0xFFE72F9A),
                                            Icons.lunch_dining_rounded,
                                            .2,
                                          ),
                                          pin(
                                            .98,
                                            .02,
                                            51,
                                            Color(0xFF0DBDA6),
                                            Icons.local_drink_rounded,
                                            .6,
                                          ),
                                          pin(
                                            .52,
                                            .38,
                                            86,
                                            WelcomePalette.gold,
                                            Icons.ramen_dining_rounded,
                                            0,
                                          ),
                                          pin(
                                            .96,
                                            .67,
                                            55,
                                            Color(0xFFFA851A),
                                            Icons.local_pizza_rounded,
                                            .4,
                                          ),
                                          pin(
                                            .09,
                                            .92,
                                            50,
                                            Color(0xFF6565F6),
                                            Icons.icecream_rounded,
                                            .8,
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 18),
                            HungryButton(
                              onPressed: widget.onGetStarted ?? () {},
                            ),
                            SizedBox(height: 24),
                            TextButton(
                              onPressed: widget.onLogin,
                              style: TextButton.styleFrom(
                                foregroundColor: Color(0xFFDFE9F1),
                                minimumSize: Size(100, 48),
                              ),
                              child: Text(
                                context.l10n.login,
                                style: TextStyle(
                                  fontSize: 18,
                                  decoration: TextDecoration.underline,
                                  decorationColor: Color(0xFFDFE9F1),
                                ),
                              ),
                            ),
                            SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
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

class _SceneSpace extends StatelessWidget {
  const _SceneSpace({required this.expand, required this.child});
  final bool expand;
  final Widget child;
  @override
  Widget build(BuildContext context) =>
      expand ? Expanded(child: child) : SizedBox(height: 260, child: child);
}
