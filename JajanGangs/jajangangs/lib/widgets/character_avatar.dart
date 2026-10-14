import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/user_profile.dart';

String avatarName(BuildContext context, String id) => switch (id) {
  'cat' => context.l10n.avatarCat,
  'frog' => context.l10n.avatarFrog,
  'robot' => context.l10n.avatarRobot,
  'panda' => context.l10n.avatarPanda,
  'fox' => context.l10n.avatarFox,
  'bunny' => context.l10n.avatarBunny,
  'bear' => context.l10n.avatarBear,
  'alien' => context.l10n.avatarAlien,
  'penguin' => context.l10n.avatarPenguin,
  _ => context.l10n.avatarMonster,
};

/// Original vector characters: crisp at every size, no downloads or photo URLs.
class CharacterAvatar extends StatelessWidget {
  const CharacterAvatar({super.key, required this.avatarId, this.size = 64});
  final String? avatarId;
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: AvatarCatalog.contains(avatarId)
        ? CustomPaint(painter: _CharacterPainter(avatarId!))
        : const Icon(Icons.person_rounded),
  );
}

class AvatarPicker extends StatelessWidget {
  const AvatarPicker({
    super.key,
    this.initialValue,
    required this.onChanged,
    this.enabled = true,
  });
  final String? initialValue;
  final ValueChanged<String> onChanged;
  final bool enabled;
  @override
  Widget build(BuildContext context) => FormField<String>(
    initialValue: initialValue,
    validator: (value) =>
        AvatarCatalog.contains(value) ? null : context.l10n.avatarRequired,
    builder: (field) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.l10n.avatarChoose,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(
          context.l10n.avatarHint,
          style: const TextStyle(fontSize: 13, color: Color(0xFF566370)),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, box) {
            final count = box.maxWidth < 270 ? 3 : 5;
            final width = (box.maxWidth - (count - 1) * 8) / count;
            return Wrap(
              spacing: 8,
              runSpacing: 10,
              children: AvatarCatalog.ids.map((id) {
                final selected = field.value == id;
                return SizedBox(
                  width: width,
                  child: Semantics(
                    label: avatarName(context, id),
                    selected: selected,
                    button: true,
                    enabled: enabled,
                    child: Tooltip(
                      message: avatarName(context, id),
                      child: Material(
                        color: selected
                            ? const Color(0xFFFFE6A1)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          onTap: enabled
                              ? () {
                                  field.didChange(id);
                                  onChanged(id);
                                }
                              : null,
                          borderRadius: BorderRadius.circular(16),
                          child: AnimatedContainer(
                            duration: MediaQuery.disableAnimationsOf(context)
                                ? Duration.zero
                                : const Duration(milliseconds: 150),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: selected
                                    ? const Color(0xFF143745)
                                    : const Color(0xFFDCE4E7),
                                width: selected ? 3 : 1,
                              ),
                            ),
                            child: Stack(
                              children: [
                                AspectRatio(
                                  aspectRatio: 1,
                                  child: ExcludeSemantics(
                                    child: CharacterAvatar(avatarId: id),
                                  ),
                                ),
                                if (selected)
                                  const Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Icon(
                                      Icons.check_circle_rounded,
                                      color: Color(0xFF143745),
                                      size: 20,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
        if (field.value != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              avatarName(context, field.value!),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        if (field.hasError)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Semantics(
              liveRegion: true,
              child: Text(
                field.errorText!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ),
      ],
    ),
  );
}

class _CharacterPainter extends CustomPainter {
  const _CharacterPainter(this.id);
  final String id;
  static const ink = Color(0xFF193345);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final index = AvatarCatalog.ids.indexOf(id);
    const backgrounds = [
      0xFFFFD6A2,
      0xFFB6F0C8,
      0xFFB6E2FF,
      0xFFE3CEF5,
      0xFFFFD6C0,
      0xFFF7CFE8,
      0xFFFFE5A2,
      0xFFC6EDC9,
      0xFFBEDBF6,
      0xFFDFC7FA,
    ];
    const skins = [
      0xFFF5B651,
      0xFF6ACB80,
      0xFF72BEDE,
      0xFFFFF8E8,
      0xFFF39750,
      0xFFFFF1F2,
      0xFFBD885A,
      0xFF8BD0A5,
      0xFF3B697D,
      0xFFA584D8,
    ];
    final skin = Color(skins[index]);
    void oval(double x, double y, double w, double h, Color color) =>
        canvas.drawOval(Rect.fromLTWH(x, y, w, h), Paint()..color = color);
    void line(Offset a, Offset b, {Color color = ink, double width = 3}) =>
        canvas.drawLine(
          a,
          b,
          Paint()
            ..color = color
            ..strokeWidth = width
            ..strokeCap = StrokeCap.round,
        );
    void shape(Path path, Color color) {
      canvas.drawPath(path, Paint()..color = color);
      canvas.drawPath(
        path,
        Paint()
          ..color = ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeJoin = StrokeJoin.round,
      );
    }

    void ear(double x, double y, double w, double h) {
      oval(x, y, w, h, ink);
      oval(x + 2, y + 2, w - 4, h - 4, skin);
    }

    oval(1, 1, 98, 98, Color(backgrounds[index]));
    // Each silhouette has its own ears, antennae, or horns.
    if (id == 'bunny') {
      ear(25, 4, 18, 45);
      ear(57, 4, 18, 45);
      oval(31, 10, 6, 26, const Color(0xFFE8A6BC));
      oval(63, 10, 6, 26, const Color(0xFFE8A6BC));
    }
    if (id == 'cat' || id == 'fox') {
      shape(
        Path()
          ..moveTo(19, 49)
          ..lineTo(17, 16)
          ..lineTo(43, 34)
          ..close(),
        skin,
      );
      shape(
        Path()
          ..moveTo(57, 34)
          ..lineTo(83, 16)
          ..lineTo(81, 49)
          ..close(),
        skin,
      );
      shape(
        Path()
          ..moveTo(24, 37)
          ..lineTo(23, 25)
          ..lineTo(35, 35)
          ..close(),
        const Color(0xFFEAA3A3),
      );
    }
    if (id == 'bear' || id == 'panda') {
      ear(13, 23, 28, 28);
      ear(59, 23, 28, 28);
      if (id == 'panda') {
        oval(16, 26, 22, 22, ink);
        oval(62, 26, 22, 22, ink);
      }
    }
    if (id == 'alien' || id == 'robot') {
      line(const Offset(50, 30), const Offset(50, 13));
      oval(44, 6, 12, 12, id == 'robot' ? const Color(0xFFFF946F) : ink);
    }
    if (id == 'monster') {
      shape(
        Path()
          ..moveTo(20, 41)
          ..lineTo(21, 15)
          ..lineTo(38, 32)
          ..close(),
        const Color(0xFFFFDB85),
      );
      shape(
        Path()
          ..moveTo(64, 32)
          ..lineTo(80, 15)
          ..lineTo(81, 41)
          ..close(),
        const Color(0xFFFFDB85),
      );
    }
    if (id == 'robot') {
      oval(7, 47, 14, 23, ink);
      oval(79, 47, 14, 23, ink);
      final head = RRect.fromRectAndRadius(
        const Rect.fromLTWH(17, 28, 66, 61),
        const Radius.circular(15),
      );
      canvas.drawRRect(head, Paint()..color = skin);
      canvas.drawRRect(
        head,
        Paint()
          ..color = ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(25, 40, 50, 25),
          const Radius.circular(9),
        ),
        Paint()..color = ink,
      );
    } else {
      oval(15, 28, 70, 62, ink);
      oval(18, 30, 64, 57, skin);
    }
    if (id == 'frog') {
      ear(20, 20, 25, 29);
      ear(55, 20, 25, 29);
    }
    if (id == 'panda') {
      oval(26, 43, 20, 23, ink);
      oval(54, 43, 20, 23, ink);
    }
    if (id == 'fox' || id == 'penguin' || id == 'bear') {
      oval(27, 52, 46, 32, const Color(0xFFFFEACF));
    }
    if (id == 'monster') {
      oval(33, 38, 34, 32, Colors.white);
      oval(44, 43, 14, 19, ink);
      oval(46, 44, 5, 6, Colors.white);
    } else {
      final eyeY = id == 'frog' ? 33.0 : 49.0;
      final whiteEyes = id == 'panda' || id == 'robot';
      oval(31, eyeY, 9, 12, whiteEyes ? Colors.white : ink);
      if (id == 'cat' || id == 'fox') {
        line(Offset(59, eyeY + 6), Offset(65, eyeY + 2));
        line(Offset(65, eyeY + 2), Offset(70, eyeY + 7));
      } else {
        oval(60, eyeY, 9, 12, whiteEyes ? Colors.white : ink);
      }
      if (!whiteEyes) oval(33, eyeY + 1, 3, 4, Colors.white);
    }
    if (id == 'robot') {
      for (var x = 35.0; x < 70; x += 10) {
        line(Offset(x, 75), Offset(x + 4, 75), width: 4);
      }
    } else {
      if (id == 'penguin') {
        shape(
          Path()
            ..moveTo(42, 63)
            ..lineTo(59, 63)
            ..lineTo(50, 72)
            ..close(),
          const Color(0xFFFFC354),
        );
      } else {
        canvas.drawArc(
          const Rect.fromLTWH(37, 62, 26, 16),
          0,
          3.14,
          false,
          Paint()
            ..color = ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round,
        );
        if (id == 'frog' || id == 'monster') {
          oval(48, 72, 9, 9, const Color(0xFFEF8E9B));
        }
        if (id == 'bunny') {
          canvas.drawRect(
            const Rect.fromLTWH(46, 71, 8, 7),
            Paint()..color = Colors.white,
          );
          line(const Offset(50, 71), const Offset(50, 77), width: 1);
        }
      }
      oval(23, 63, 11, 6, const Color(0x55EF779A));
      oval(67, 63, 11, 6, const Color(0x55EF779A));
    }
    if (id == 'cat') {
      line(const Offset(12, 60), const Offset(25, 63), width: 2);
      line(const Offset(75, 63), const Offset(88, 60), width: 2);
    }
    // Tiny bandana ties the collection to the food-adventure theme.
    shape(
      Path()
        ..moveTo(35, 85)
        ..lineTo(65, 85)
        ..lineTo(51, 97)
        ..close(),
      const Color(0xFFED795A),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CharacterPainter oldDelegate) =>
      oldDelegate.id != id;
}
