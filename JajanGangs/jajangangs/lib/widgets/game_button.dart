import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Tactile game-style control, retaining Flutter's keyboard/focus semantics.
class GameButton extends StatefulWidget {
  const GameButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.secondary = false,
    this.icon,
  });
  final String label;
  final VoidCallback onPressed;
  final bool secondary;
  final IconData? icon;
  @override
  State<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<GameButton> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 100),
        transform: Matrix4.translationValues(0, _pressed ? 4 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink,
              offset: Offset(0, _pressed ? 1 : 5),
            ),
          ],
        ),
        child: FilledButton(
          onPressed: widget.onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: widget.secondary
                ? AppColors.cream
                : AppColors.lime,
            foregroundColor: AppColors.ink,
            side: const BorderSide(color: AppColors.ink, width: 2),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 17),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(child: Text(widget.label)),
              if (widget.icon != null) ...[
                const SizedBox(width: 12),
                Icon(widget.icon, size: 22),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
