import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Original vector artwork; scales cleanly without remote image dependencies.
class WelcomeArtwork extends StatelessWidget {
  const WelcomeArtwork({super.key});
  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: 'A happy noodle bowl surrounded by friends on a playful neighborhood map',
    child: ExcludeSemantics(
      child: AspectRatio(
        aspectRatio: 1.22,
        child: CustomPaint(painter: _FoodGangPainter()),
      ),
    ),
  );
}

class _FoodGangPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 360, size.height / 295);
    final fill = Paint();
    final line = Paint()
      ..color = AppColors.ink
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    void oval(Rect rect, Color color) {
      canvas.drawOval(rect, fill..color = color);
      canvas.drawOval(rect, line);
    }

    void tile(Rect rect, Color color, double radius) {
      final rounded = RRect.fromRectAndRadius(rect, Radius.circular(radius));
      canvas.drawRRect(rounded, fill..color = color);
      canvas.drawRRect(rounded, line);
    }

    // Neighborhood island and little streets.
    canvas.drawOval(
      const Rect.fromLTWH(33, 85, 299, 183),
      fill..color = const Color(0xFFE8E8D7),
    );
    tile(const Rect.fromLTWH(24, 64, 310, 184), const Color(0xFFEBEEDC), 48);
    final road = Paint()
      ..color = AppColors.cream
      ..strokeWidth = 24
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(30, 182)
        ..cubicTo(100, 210, 175, 90, 331, 127),
      road,
    );
    canvas.drawPath(
      Path()
        ..moveTo(118, 68)
        ..lineTo(135, 240),
      road,
    );
    // Trees and playful destination squares.
    tile(const Rect.fromLTWH(264, 183, 39, 30), AppColors.lavender, 8);
    tile(const Rect.fromLTWH(58, 98, 31, 25), AppColors.orange, 6);
    for (final point in [const Offset(64, 215), const Offset(291, 91)]) {
      canvas.drawLine(point, point.translate(0, 13), line);
      oval(
        Rect.fromCircle(center: point.translate(0, -7), radius: 12),
        AppColors.lime,
      );
    }
    // Bowl shadow, body and noodles.
    canvas.drawOval(
      const Rect.fromLTWH(108, 217, 152, 24),
      fill..color = const Color(0xFFCCD2B5),
    );
    final bowl = Path()
      ..moveTo(100, 145)
      ..lineTo(260, 145)
      ..quadraticBezierTo(252, 228, 180, 230)
      ..quadraticBezierTo(109, 228, 100, 145)
      ..close();
    canvas.drawPath(bowl, fill..color = AppColors.orange);
    canvas.drawPath(bowl, line);
    oval(const Rect.fromLTWH(99, 121, 162, 53), AppColors.cream);
    oval(const Rect.fromLTWH(112, 131, 136, 31), const Color(0xFFFFD16B));
    final noodle = Paint()
      ..color = const Color(0xFFCD792A)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 5; i++) {
      final x = 127.0 + i * 23;
      canvas.drawPath(
        Path()
          ..moveTo(x, 139)
          ..quadraticBezierTo(x - 10, 153, x + 6, 154)
          ..quadraticBezierTo(x + 20, 145, x + 8, 137),
        noodle,
      );
    }
    oval(const Rect.fromLTWH(198, 125, 30, 23), Colors.white);
    canvas.drawOval(
      const Rect.fromLTWH(207, 131, 13, 11),
      fill..color = const Color(0xFFFFC349),
    );
    canvas.drawLine(
      const Offset(200, 137),
      const Offset(258, 62),
      line..strokeWidth = 5,
    );
    canvas.drawLine(const Offset(211, 139), const Offset(272, 69), line);
    line.strokeWidth = 3;
    // Friendly face.
    for (final x in [157.0, 204.0]) {
      canvas.drawCircle(Offset(x, 188), 4, fill..color = AppColors.ink);
    }
    canvas.drawArc(
      const Rect.fromLTWH(170, 185, 22, 19),
      0.2,
      2.7,
      false,
      line,
    );
    canvas.drawOval(
      const Rect.fromLTWH(140, 195, 17, 7),
      fill..color = const Color(0xFFFFB199),
    );
    canvas.drawOval(const Rect.fromLTWH(205, 195, 17, 7), fill);
    // Steam.
    for (final x in [151.0, 175.0, 198.0]) {
      canvas.drawPath(
        Path()
          ..moveTo(x, 113)
          ..cubicTo(x - 12, 100, x + 11, 94, x, 80),
        line,
      );
    }
    // Two gang avatars.
    void friend(Offset point, Color color) {
      oval(
        Rect.fromCircle(center: point.translate(0, 4), radius: 27),
        AppColors.ink,
      );
      oval(Rect.fromCircle(center: point, radius: 27), color);
      for (final dx in [-8.0, 8.0]) {
        canvas.drawCircle(
          point.translate(dx, -3),
          2.6,
          fill..color = AppColors.ink,
        );
      }
      canvas.drawArc(
        Rect.fromCenter(center: point.translate(0, 5), width: 14, height: 10),
        0,
        3.14,
        false,
        line,
      );
    }

    friend(const Offset(54, 158), AppColors.lavender);
    friend(const Offset(294, 151), AppColors.lime);
    // Sparkles.
    for (final p in [
      const Offset(91, 51),
      const Offset(305, 39),
      const Offset(242, 257),
    ]) {
      canvas.drawLine(p.translate(-6, 0), p.translate(6, 0), line);
      canvas.drawLine(p.translate(0, -6), p.translate(0, 6), line);
    }
    canvas.drawCircle(const Offset(30, 76), 4, fill..color = AppColors.orange);
    canvas.drawCircle(
      const Offset(322, 231),
      5,
      fill..color = AppColors.lavender,
    );
  }

  @override
  bool shouldRepaint(_FoodGangPainter oldDelegate) => false;
}
