import '../l10n/l10n.dart';

import 'package:flutter/material.dart';

abstract final class WelcomePalette {
  static const navy = Color(0xFF071E32);
  static const gold = Color(0xFFFFCB3E);
  static const orange = Color(0xFFFF922B);
}

/// Live text over layered outlines, keeping branding sharp on all screens.
class GameLogo extends StatelessWidget {
  const GameLogo({super.key});

  Widget _word(String text, double size, List<Color> colors) {
    final style = TextStyle(
      fontSize: size,
      height: 1,
      fontWeight: FontWeight.w900,
      letterSpacing: -2.5,
    );
    return Stack(
      alignment: Alignment.center,
      children: [
        Text(
          text,
          style: style.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 15
              ..strokeJoin = StrokeJoin.round
              ..color = Color(0xFF427298),
          ),
        ),
        Text(
          text,
          style: style.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 10
              ..strokeJoin = StrokeJoin.round
              ..color = WelcomePalette.navy,
          ),
        ),
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: colors,
          ).createShader(bounds),
          child: Text(text, style: style.copyWith(color: Colors.white)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Jajan Gangs',
    header: true,
    child: ExcludeSemantics(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Transform.rotate(
          angle: -0.045,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.workspace_premium_rounded,
                color: WelcomePalette.gold,
                size: 39,
              ),
              _word('JAJAN', 76, [
                Color(0xFFFFE477),
                WelcomePalette.gold,
                WelcomePalette.orange,
              ]),
              _word('GANGS', 49, [Colors.white, Color(0xFFFFF1DA)]),
            ],
          ),
        ),
      ),
    ),
  );
}

class FoodPin extends StatelessWidget {
  const FoodPin({
    super.key,
    required this.color,
    required this.icon,
    this.size = 65,
  });
  final Color color;
  final IconData icon;
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size * 1.48,
    child: Stack(
      alignment: Alignment.topCenter,
      children: [
        Positioned(
          bottom: 0,
          child: Container(
            width: size * .85,
            height: size * .26,
            decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: color.withValues(alpha: .7), width: 2),
              color: color.withValues(alpha: .22),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: .5),
                  blurRadius: 22,
                  spreadRadius: 4,
                ),
              ],
            ),
          ),
        ),
        CustomPaint(size: Size(size, size * 1.35), painter: _PinPainter(color)),
        Positioned(
          top: size * .15,
          child: Container(
            width: size * .64,
            height: size * .64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: .32),
              border: Border.all(
                color: Colors.white.withValues(alpha: .4),
                width: 1.5,
              ),
            ),
            child: Icon(icon, color: Color(0xFFFFF6DF), size: size * .4),
          ),
        ),
      ],
    ),
  );
}

class _PinPainter extends CustomPainter {
  const _PinPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final path = Path()
      ..moveTo(w / 2, size.height)
      ..cubicTo(w * .35, size.height * .82, 0, w * .75, 0, w * .48)
      ..cubicTo(0, -w * .15, w, -w * .15, w, w * .48)
      ..cubicTo(w, w * .75, w * .65, size.height * .82, w / 2, size.height)
      ..close();
    canvas.drawShadow(path, color, 9, false);
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(color, Colors.white, .25)!, color],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Color.lerp(color, Colors.white, .55)!,
    );
  }

  @override
  bool shouldRepaint(_PinPainter oldDelegate) => oldDelegate.color != color;
}

class HungryButton extends StatefulWidget {
  const HungryButton({super.key, required this.onPressed});
  final VoidCallback onPressed;
  @override
  State<HungryButton> createState() => _HungryButtonState();
}

class _HungryButtonState extends State<HungryButton> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => setState(() => _pressed = true),
    onPointerUp: (_) => setState(() => _pressed = false),
    onPointerCancel: (_) => setState(() => _pressed = false),
    child: AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : Duration(milliseconds: 90),
      transform: Matrix4.translationValues(0, _pressed ? 5 : 0, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(46),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFE47C), WelcomePalette.gold, Color(0xFFFFB52D)],
        ),
        border: Border.all(color: WelcomePalette.navy, width: 4),
        boxShadow: [
          BoxShadow(
            color: WelcomePalette.navy,
            offset: Offset(0, _pressed ? 2 : 8),
          ),
          BoxShadow(color: Color(0x554CA4BA), blurRadius: 26, spreadRadius: 1),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(3),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(39),
            border: Border.all(color: Color(0xFFFFEDAA), width: 3),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(38),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: widget.onPressed,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 17, vertical: 19),
                child: Row(
                  children: [
                    Icon(
                      Icons.restaurant_rounded,
                      size: 35,
                      color: WelcomePalette.navy,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            context.l10n.hungry,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28,
                              height: 1.1,
                              fontWeight: FontWeight.w900,
                              color: WelcomePalette.navy,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            context.l10n.letsJajan,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: WelcomePalette.navy,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 10),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 29,
                      color: WelcomePalette.navy,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
