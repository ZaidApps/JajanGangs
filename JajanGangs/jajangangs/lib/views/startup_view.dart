import '../l10n/l10n.dart';

import 'package:flutter/material.dart';

import '../controllers/startup_controller.dart';
import '../models/startup_state.dart';
import '../widgets/app_feedback.dart';
import 'welcome_view.dart';

class StartupView extends StatefulWidget {
  const StartupView({super.key, required this.controller});
  final StartupController controller;
  @override
  State<StartupView> createState() => _StartupViewState();
}

class _StartupViewState extends State<StartupView> {
  @override
  void initState() {
    super.initState();
    widget.controller.start();
  }

  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) => switch (widget.controller.state.status) {
      StartupStatus.ready => const WelcomeView(),
      StartupStatus.loading => const Scaffold(
        body: SafeArea(child: AppLoading()),
      ),
      StartupStatus.failed => Scaffold(
        body: SafeArea(
          child: AppError(
            message: context.l10n.message(widget.controller.state.message!),
            onRetry: widget.controller.start,
          ),
        ),
      ),
    },
  );
}
