import 'package:flutter/material.dart';

/// Shared dialog treatment for confirmations, notices and small forms.
class GameDialog extends StatelessWidget {
  const GameDialog({
    super.key,
    required this.title,
    this.content,
    this.actions,
    this.icon,
    this.scrollable = false,
  });
  final Widget title;
  final Widget? content, icon;
  final List<Widget>? actions;
  final bool scrollable;

  @override
  Widget build(BuildContext context) => Theme(
    data: Theme.of(context).copyWith(
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFFFCD61),
          foregroundColor: const Color(0xFF102C42),
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF176F72),
          minimumSize: const Size(48, 48),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
    ),
    child: AlertDialog(
      scrollable: scrollable,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      titlePadding: EdgeInsets.zero,
      title: Container(
        padding: const EdgeInsets.all(22),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF102C42), Color(0xFF176F72)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(27)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFCD61),
                borderRadius: BorderRadius.circular(14),
              ),
              child: IconTheme(
                data: const IconThemeData(color: Color(0xFF102C42), size: 24),
                child: icon ?? const Icon(Icons.chat_bubble_outline_rounded),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: DefaultTextStyle(
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  height: 1.25,
                  fontWeight: FontWeight.w900,
                ),
                child: title,
              ),
            ),
          ],
        ),
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 22, 24, 8),
      content: content,
      actionsPadding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      actionsOverflowButtonSpacing: 8,
      actions: actions,
    ),
  );
}
