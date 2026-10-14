import 'dart:async';

import 'package:flutter/material.dart';

import 'controllers/locale_controller.dart';
import 'l10n/l10n.dart';
import 'services/auth_gateway.dart';
import 'services/chat_route_observer.dart';
import 'theme/app_theme.dart';
import 'views/auth/auth_gate.dart';
import 'widgets/branded_launch.dart';

class JajanGangsApp extends StatefulWidget {
  const JajanGangsApp({super.key, this.authGateway});
  final AuthGateway? authGateway;
  @override
  State<JajanGangsApp> createState() => _JajanGangsAppState();
}

class _JajanGangsAppState extends State<JajanGangsApp> {
  final _language = LocaleController();
  @override
  void initState() {
    super.initState();
    unawaited(_language.restore());
  }

  @override
  void dispose() {
    _language.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LocaleScope(
    controller: _language,
    child: ListenableBuilder(
      listenable: _language,
      builder: (context, _) => MaterialApp(
        title: 'Jajan Gangs',
        debugShowCheckedModeBanner: false,
        navigatorObservers: [chatRouteObserver],
        locale: _language.locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.light,
        builder: (context, child) => BrandedLaunch(child: child!),
        home: AuthGate(gateway: widget.authGateway),
      ),
    ),
  );
}
