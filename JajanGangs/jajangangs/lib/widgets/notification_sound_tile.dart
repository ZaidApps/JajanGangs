import 'package:flutter/material.dart';

import '../services/notification_sound.dart';
import '../l10n/l10n.dart';

class NotificationSoundTile extends StatelessWidget {
  const NotificationSoundTile({super.key});
  @override
  Widget build(BuildContext context) {
    final sound = NotificationSound.instance;
    return ListenableBuilder(
      listenable: sound,
      builder: (context, _) => SwitchListTile(
        contentPadding: EdgeInsets.zero,
        secondary: Icon(
          sound.enabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
        ),
        title: Text(context.l10n.notificationSound),
        subtitle: Text(context.l10n.notificationSoundHint),
        value: sound.enabled,
        onChanged: sound.saving
            ? null
            : (value) async {
                final saved = await sound.setEnabled(value);
                if (!saved && context.mounted)
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.l10n.notificationSoundSaveError),
                    ),
                  );
              },
      ),
    );
  }
}
