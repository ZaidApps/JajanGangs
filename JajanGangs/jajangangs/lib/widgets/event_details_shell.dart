import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import 'language_selector.dart';
import 'welcome_game_elements.dart';

/// Compact event form with primary actions outside the scrollable details.
class EventDetailsShell extends StatelessWidget {
  const EventDetailsShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.accent,
    required this.icon,
    required this.children,
    this.primaryActions = const [],
    this.onBack,
  });
  final String title, subtitle, badge;
  final Color accent;
  final IconData icon;
  final List<Widget> children, primaryActions;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: WelcomePalette.navy,
    body: Stack(
      fit: StackFit.expand,
      children: [
        const ExcludeSemantics(
          child: Image(
            image: AssetImage('assets/images/welcome_city.png'),
            fit: BoxFit.cover,
          ),
        ),
        const ColoredBox(color: Color(0xCE071E32)),
        SafeArea(
          child: LayoutBuilder(
            builder: (context, bounds) => Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 440,
                    maxHeight:
                        (bounds.maxHeight - 28).clamp(0.0, double.infinity) *
                        .94,
                  ),
                  child: Material(
                    color: const Color(0xFFFFFAEF),
                    borderRadius: BorderRadius.circular(24),
                    clipBehavior: Clip.antiAlias,
                    elevation: 12,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.fromLTRB(8, 2, 8, 2),
                          color: WelcomePalette.navy,
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: onBack,
                                tooltip: context.l10n.back,
                                icon: const Icon(
                                  Icons.arrow_back_rounded,
                                  color: Colors.white,
                                ),
                              ),
                              const Expanded(
                                child: Text(
                                  'JAJAN GANGS',
                                  style: TextStyle(
                                    color: WelcomePalette.gold,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                              const LanguageSelector(),
                            ],
                          ),
                        ),
                        Flexible(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        accent,
                                        Color.lerp(accent, Colors.white, .65)!,
                                      ],
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(9),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: .8,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        child: Icon(
                                          icon,
                                          size: 27,
                                          color: WelcomePalette.navy,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              badge,
                                              style: const TextStyle(
                                                color: WelcomePalette.navy,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              title,
                                              style: const TextStyle(
                                                color: WelcomePalette.navy,
                                                fontSize: 21,
                                                height: 1.15,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              subtitle,
                                              style: TextStyle(
                                                color: WelcomePalette.navy
                                                    .withValues(alpha: .8),
                                                fontSize: 12,
                                                height: 1.3,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: children,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (primaryActions.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFFAEF),
                              border: Border(
                                top: BorderSide(color: Color(0xFFE0E7DE)),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: primaryActions,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
