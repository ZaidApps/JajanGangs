import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/l10n.dart';

String jajanScheduleTime(BuildContext context, DateTime time) {
  final local = time.toLocal();
  final offset = local.timeZoneOffset;
  final minutes = offset.inMinutes.abs();
  final zone =
      'UTC${offset.isNegative ? '-' : '+'}${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';
  return '${DateFormat.yMMMd(Localizations.localeOf(context).languageCode).add_Hm().format(local)} ($zone)';
}

/// Pure local presentation. No streams, timers or database reads.
class JajanScheduleBadge extends StatelessWidget {
  const JajanScheduleBadge({
    super.key,
    required this.time,
    this.compact = false,
  });
  final DateTime? time;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    if (time == null) return const SizedBox.shrink();
    final label = context.l10n.jajanScheduledFor(
      jajanScheduleTime(context, time!),
    );
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 0 : 10,
        vertical: compact ? 2 : 8,
      ),
      decoration: BoxDecoration(
        color: compact ? Colors.transparent : const Color(0xFFECE6FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        maxLines: compact ? 1 : null,
        overflow: compact ? TextOverflow.ellipsis : null,
        style: TextStyle(
          color: const Color(0xFF584095),
          fontSize: compact ? 11 : 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
