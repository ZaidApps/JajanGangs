import 'package:flutter/material.dart';

import '../controllers/locale_controller.dart';
import '../l10n/l10n.dart';
import 'welcome_game_elements.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = LocaleScope.of(context);
    return PopupMenuButton<String>(
      tooltip: context.l10n.language,
      initialValue: controller.locale.languageCode,
      onSelected: (code) async {
        final saved = await controller.select(code);
        if (!saved && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.languageSaveError)),
          );
        }
      },
      itemBuilder: (_) => [
        CheckedPopupMenuItem(
          value: 'en',
          checked: controller.locale.languageCode == 'en',
          child: const Text('English'),
        ),
        CheckedPopupMenuItem(
          value: 'id',
          checked: controller.locale.languageCode == 'id',
          child: const Text('Bahasa Indonesia'),
        ),
      ],
      child: Container(
        constraints: const BoxConstraints(minHeight: 48, minWidth: 76),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: WelcomePalette.navy.withValues(alpha: .85),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: WelcomePalette.gold.withValues(alpha: .65)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.language_rounded,
              size: 18,
              color: WelcomePalette.gold,
            ),
            const SizedBox(width: 7),
            Text(
              controller.locale.languageCode.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Icon(
              Icons.expand_more_rounded,
              color: Colors.white,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
