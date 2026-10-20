import '../../widgets/game_dialog.dart';
import '../../l10n/l10n.dart';

import 'dart:async';

import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/locale_controller.dart';
import '../../models/auth_session.dart';
import '../../services/auth_gateway.dart';
import '../../services/firebase_auth_gateway.dart';
import '../../services/announcement_service.dart';
import '../../services/notification_sound.dart';
import '../welcome_view.dart';
import '../map_view.dart';
import 'auth_flow_view.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key, this.gateway});
  final AuthGateway? gateway;
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final AnnouncementService _announcements = AnnouncementService(
    explainPermission: () async {
      if (!mounted || controller.page != AuthPage.complete) return false;
      return await showDialog<bool>(
            context: context,
            builder: (context) => GameDialog(
              icon: const Icon(Icons.campaign_rounded),
              title: Text(context.l10n.announcementPermissionTitle),
              content: Text(context.l10n.announcementPermissionBody),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(context.l10n.announcementLater),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(context.l10n.announcementEnable),
                ),
              ],
            ),
          ) ??
          false;
    },
    onMessage: (message) {
      if (!mounted || message.notification == null) return;
      final notification = message.notification!;
      final text = [
        notification.title,
        notification.body,
      ].whereType<String>().join('\n');
      if (text.isEmpty) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(text),
          duration: const Duration(seconds: 8),
          showCloseIcon: true,
        ),
      );
      unawaited(NotificationSound.instance.play());
    },
  );

  void _syncAnnouncements() {
    if (widget.gateway != null || controller.restoring) return;
    if (controller.page != AuthPage.complete && controller.user != null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || controller.restoring) return;
      if (controller.page == AuthPage.complete) {
        _announcements.updateMember(true);
      } else if (controller.user == null) {
        _announcements.updateMember(false);
      }
    });
  }

  late final AuthController controller = AuthController(
    widget.gateway ??
        FirebaseAuthGateway(
          languageCode: () => LocaleScope.of(context).locale.languageCode,
        ),
  );
  @override
  void initState() {
    super.initState();
    controller.addListener(_syncAnnouncements);
    unawaited(controller.restore());
  }

  @override
  void dispose() {
    controller.removeListener(_syncAnnouncements);
    _announcements.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => controller.page == AuthPage.welcome
        ? Stack(
            children: [
              WelcomeView(
                onGetStarted: () => controller.show(AuthPage.register),
                onLogin: () => controller.show(AuthPage.login),
              ),
              if (controller.restoring)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    semanticsLabel: context.l10n.restoring,
                  ),
                ),
            ],
          )
        : controller.page == AuthPage.complete
        ? MapView(auth: controller)
        : AuthFlowView(controller: controller),
  );
}
