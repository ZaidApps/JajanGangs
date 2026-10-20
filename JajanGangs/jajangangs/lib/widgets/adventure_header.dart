import 'package:flutter/material.dart';

/// Shared visual language for personal spaces and food memories.
class AdventureHeader extends StatelessWidget {
  const AdventureHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.leading,
  });
  final String title, subtitle;
  final IconData icon;
  final Widget? leading;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF102C42), Color(0xFF176F72)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(26),
      boxShadow: const [
        BoxShadow(
          color: Color(0x20102C42),
          blurRadius: 18,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFCE62),
                borderRadius: BorderRadius.circular(20),
              ),
              child:
                  leading ??
                  Icon(icon, size: 30, color: const Color(0xFF102C42)),
            ),
            const Spacer(),
            const Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFFFFCE62),
              size: 28,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFFD1ECE6),
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ],
    ),
  );
}
