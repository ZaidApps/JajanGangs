import '../l10n/l10n.dart';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Visual shell only: native integrations are verified on Android/iOS.
class WebPreviewView extends StatelessWidget {
  const WebPreviewView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Jajan Gangs')),
    body: Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.large),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.ramen_dining_rounded,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              SizedBox(height: AppSpacing.large),
              Text(
                context.l10n.mapSlogan,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              SizedBox(height: AppSpacing.medium),
              Text(context.l10n.previewIntro, textAlign: TextAlign.center),
              SizedBox(height: AppSpacing.large),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.large),
                  child: Column(
                    children: [
                      Icon(Icons.phone_android_rounded),
                      SizedBox(height: AppSpacing.medium),
                      Text(
                        context.l10n.browserPreview,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: AppSpacing.small),
                      Text(
                        context.l10n.previewDetails,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
