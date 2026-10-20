import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/l10n.dart';
import '../models/home_map_state.dart';
import 'character_avatar.dart';
import 'jajan_schedule_badge.dart';
import 'game_map_canvas.dart';
import 'welcome_game_elements.dart';

/// A presentation of the map's existing event snapshot; no data access here.
class NearbyJajanCard extends StatelessWidget {
  const NearbyJajanCard({
    super.key,
    required this.event,
    required this.area,
    required this.selected,
    required this.onTap,
  });
  final MapJajan event;
  final MapArea area;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final accent = foodColor(event.kind);
    const navy = WelcomePalette.navy;
    final full = event.members >= event.capacity;
    final number = NumberFormat(
      '0.#',
      Localizations.localeOf(context).languageCode,
    );
    return Container(
      width: 250,
      margin: const EdgeInsets.fromLTRB(2, 4, 12, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: navy.withValues(alpha: selected ? .25 : .12),
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: const Color(0xFFFFFEF8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: selected ? navy : const Color(0xFFD5E2DC),
            width: selected ? 2.5 : 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Ink(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accent, Color.lerp(accent, Colors.white, .6)!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .8),
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(color: navy.withValues(alpha: .12)),
                      ),
                      child: Icon(foodIcon(event.kind), color: navy, size: 24),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        mapEventTitle(context, event),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: navy,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: .22),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: navy.withValues(alpha: .15),
                            ),
                          ),
                          child: CharacterAvatar(
                            avatarId: event.creatorAvatarId,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event.scheduledAt == null
                                    ? l.eventHost
                                    : l.jajanScheduledFor(
                                        jajanScheduleTime(
                                          context,
                                          event.scheduledAt!,
                                        ),
                                      ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF53736F),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                event.creatorName ?? l.foodie,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: navy,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (event.description.isNotEmpty) ...[
                      const SizedBox(height: 7),
                      Text(
                        event.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF53736F),
                          height: 1.3,
                        ),
                      ),
                    ],
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        const Icon(Icons.groups_rounded, color: navy, size: 18),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            l.jajanMemberCount(event.members, event.capacity),
                            style: const TextStyle(
                              color: navy,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: LinearProgressIndicator(
                        value: event.capacity <= 0
                            ? 0
                            : (event.members / event.capacity).clamp(0.0, 1.0),
                        minHeight: 5,
                        color: full
                            ? const Color(0xFF53736F)
                            : const Color(0xFF159F7B),
                        backgroundColor: const Color(0xFFE6EEEA),
                      ),
                    ),
                    if (!area.isFallback) ...[
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          const Icon(
                            Icons.near_me_outlined,
                            size: 14,
                            color: Color(0xFF53736F),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              event.distanceKm(area) < 1
                                  ? l.eventSameArea
                                  : l.homeDistance(
                                      number.format(event.distanceKm(area)),
                                    ),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF53736F),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            full ? l.eventFull : l.eventDetails,
                            style: const TextStyle(
                              color: navy,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 19,
                            color: navy,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
