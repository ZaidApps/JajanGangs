import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

class DumplingRating extends StatelessWidget {
  const DumplingRating({super.key, required this.value, this.onChanged});
  final int value;
  final ValueChanged<int>? onChanged;
  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    children: List.generate(
      5,
      (i) => Semantics(
        label: context.l10n.dumplingRating(i + 1),
        selected: value == i + 1,
        button: onChanged != null,
        child: Tooltip(
          message: context.l10n.dumplingRating(i + 1),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: onChanged == null ? null : () => onChanged!(i + 1),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: CustomPaint(
                size: const Size(40, 40),
                painter: _Dumpling(i < value, value),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _Dumpling extends CustomPainter {
  _Dumpling(this.selected, this.rating);
  final bool selected;
  final int rating;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 40, size.height / 40);
    final outline = Paint()
      ..color = const Color(0xFF102C42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final shape = Path()
      ..moveTo(3, 29)
      ..quadraticBezierTo(1, 19, 10, 13)
      ..quadraticBezierTo(13, 8, 20, 6)
      ..quadraticBezierTo(28, 9, 31, 14)
      ..quadraticBezierTo(40, 22, 36, 30)
      ..quadraticBezierTo(20, 39, 3, 29)
      ..close();
    canvas.drawPath(
      shape,
      Paint()
        ..color = selected ? const Color(0xFFFFC647) : const Color(0xFFE2E6DE),
    );
    canvas.drawPath(shape, outline);
    for (final x in [14.0, 20.0, 26.0]) {
      canvas.drawLine(Offset(20, 8), Offset(x, 16), outline);
    }
    canvas.drawCircle(
      const Offset(13, 23),
      1.7,
      Paint()..color = outline.color,
    );
    canvas.drawCircle(
      const Offset(27, 23),
      1.7,
      Paint()..color = outline.color,
    );
    final mouth = Path()
      ..moveTo(16, 28)
      ..quadraticBezierTo(20, rating >= 3 ? 33 : 26, 24, 28);
    canvas.drawPath(mouth, outline);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _Dumpling old) =>
      selected != old.selected || rating != old.rating;
}
