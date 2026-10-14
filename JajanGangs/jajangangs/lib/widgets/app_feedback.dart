import '../l10n/l10n.dart';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_button.dart';

class AppLoading extends StatelessWidget {
  const AppLoading({super.key, this.label});
  final String? label;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: AppSpacing.medium),
        Text(label ?? context.l10n.preparingApp),
      ],
    ),
  );
}

class AppError extends StatelessWidget {
  const AppError({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.large),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sentiment_dissatisfied_rounded, size: 40),
          SizedBox(height: AppSpacing.medium),
          Text(message, textAlign: TextAlign.center),
          SizedBox(height: AppSpacing.medium),
          AppButton(label: context.l10n.retry, onPressed: onRetry),
        ],
      ),
    ),
  );
}
