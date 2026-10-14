import 'language_selector.dart';
import '../l10n/l10n.dart';

import 'package:flutter/material.dart';

import 'welcome_game_elements.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.onBack,
    this.badge,
  });
  final String title;
  final String subtitle;
  final String? badge;
  final List<Widget> children;
  final VoidCallback? onBack;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: WelcomePalette.navy,
    body: Stack(
      fit: StackFit.expand,
      children: [
        ExcludeSemantics(
          child: Image(
            image: AssetImage('assets/images/welcome_city.png'),
            fit: BoxFit.cover,
          ),
        ),
        ColoredBox(color: Color(0xCE071E32)),
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 22, vertical: 22),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        if (onBack != null)
                          IconButton(
                            onPressed: onBack,
                            tooltip: context.l10n.back,
                            icon: Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            'JAJAN GANGS',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: WelcomePalette.gold,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        const LanguageSelector(),
                      ],
                    ),
                    SizedBox(height: 24),
                    Container(
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Color(0xFFFFFAEF),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: WelcomePalette.navy,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xCC03111E),
                            offset: Offset(0, 8),
                          ),
                          BoxShadow(color: Color(0x335BD5FF), blurRadius: 28),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: Color(0xFFFFE5A0),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                badge ?? context.l10n.adventureBadge,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: .8,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 18),
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 30,
                              height: 1.12,
                              fontWeight: FontWeight.w900,
                              color: WelcomePalette.navy,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.45,
                              color: Color(0xFF566370),
                            ),
                          ),
                          SizedBox(height: 24),
                          ...children,
                        ],
                      ),
                    ),
                    SizedBox(height: 22),
                    Text(
                      context.l10n.tagline,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFD5E5EE),
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class AuthAction extends StatelessWidget {
  const AuthAction({
    super.key,
    required this.label,
    this.onPressed,
    this.busy = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: busy ? null : onPressed,
    style: FilledButton.styleFrom(
      backgroundColor: WelcomePalette.gold,
      foregroundColor: WelcomePalette.navy,
      disabledBackgroundColor: Color(0xFFF0DEA7),
      padding: EdgeInsets.symmetric(vertical: 17, horizontal: 16),
      side: BorderSide(color: WelcomePalette.navy, width: 2),
    ),
    child: busy
        ? Semantics(
            label: context.l10n.loading,
            child: SizedBox.square(
              dimension: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: WelcomePalette.navy,
              ),
            ),
          )
        : Text(label, textAlign: TextAlign.center),
  );
}

class AuthMessage extends StatelessWidget {
  const AuthMessage({super.key, required this.text, this.isError = false});
  final String text;
  final bool isError;
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isError ? Color(0xFFFFE9E2) : Color(0xFFE4F1D9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isError ? Color(0xFF8A2819) : Color(0xFF285129),
          height: 1.4,
        ),
      ),
    ),
  );
}
