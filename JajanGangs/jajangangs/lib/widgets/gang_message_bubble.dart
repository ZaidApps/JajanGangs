import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/l10n.dart';
import '../models/gang_message.dart';
import 'character_avatar.dart';

class GangMessageBubble extends StatelessWidget {
  const GangMessageBubble({
    super.key,
    required this.message,
    required this.mine,
    this.onRetry,
  });
  final GangMessage message;
  final bool mine;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF102C42);
    final l = context.l10n;
    final failed = message.delivery == MessageDelivery.failed;
    final pending = message.delivery == MessageDelivery.pending;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: mine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!mine) ...[
            CharacterAvatar(avatarId: message.avatarId, size: 34),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: IntrinsicWidth(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width * .76,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: failed
                      ? const Color(0xFFFFDAD6)
                      : mine
                      ? const Color(0xFF8DF2CD)
                      : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(mine ? 20 : 4),
                    bottomRight: Radius.circular(mine ? 4 : 20),
                  ),
                  border: Border.all(
                    color: failed ? Colors.red.shade800 : ink,
                    width: 2,
                  ),
                  boxShadow: const [
                    BoxShadow(color: ink, offset: Offset(0, 3)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mine ? l.chatYou : message.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: ink,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      message.text,
                      style: const TextStyle(fontSize: 16, color: ink),
                    ),
                    if (failed)
                      TextButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: Text(l.chatFailed),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red.shade900,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (message.createdAt != null)
                            Text(
                              DateFormat.Hm(
                                Localizations.localeOf(context).languageCode,
                              ).format(message.createdAt!.toLocal()),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF52716C),
                              ),
                            ),
                          if (mine) ...[
                            const SizedBox(width: 6),
                            Tooltip(
                              message: failed
                                  ? l.chatFailed
                                  : pending
                                  ? l.chatPending
                                  : l.chatSent,
                              child: Icon(
                                failed
                                    ? Icons.error_outline
                                    : pending
                                    ? Icons.schedule
                                    : Icons.check_rounded,
                                size: 16,
                                color: failed ? Colors.red.shade800 : ink,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
