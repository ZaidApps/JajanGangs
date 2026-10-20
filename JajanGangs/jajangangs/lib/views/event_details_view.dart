import '../widgets/jajan_schedule_badge.dart';
import '../widgets/game_dialog.dart';
import 'jajan_complete_view.dart';
import 'invite_friends_view.dart';
import 'join_requests_view.dart';
import 'gang_chat_view.dart';
import 'event_members_view.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../controllers/event_details_controller.dart';
import '../l10n/l10n.dart';
import '../models/home_map_state.dart';
import '../models/jajan_event.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/event_details_shell.dart';
import '../widgets/character_avatar.dart';
import '../widgets/game_map_canvas.dart';
import '../widgets/welcome_game_elements.dart';

class EventDetailsView extends StatefulWidget {
  const EventDetailsView({
    super.key,
    required this.marker,
    required this.area,
    required this.uid,
    this.openRequests = false,
    this.ownerName,
    this.ownerAvatarId,
  });
  final bool openRequests;
  final MapJajan marker;
  final MapArea area;
  final String uid;
  final String? ownerName, ownerAvatarId;
  @override
  State<EventDetailsView> createState() => _EventDetailsViewState();
}

class _EventDetailsViewState extends State<EventDetailsView> {
  late final c = EventDetailsController(id: widget.marker.id, uid: widget.uid);
  @override
  void initState() {
    super.initState();
    if (!widget.marker.isDemo) unawaited(c.start());
    if (widget.openRequests)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_requests());
      });
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  Future<void> _requests() => Navigator.of(context).push<void>(
    MaterialPageRoute(builder: (_) => JoinRequestsView(controller: c)),
  );

  Future<void> _join() async {
    final publicJoin = c.event?.isPublic == true;
    final joined = await c.join();
    if (!mounted ||
        !publicJoin ||
        !joined ||
        ModalRoute.of(context)?.isCurrent != true)
      return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => GangChatView(eventId: c.id, uid: c.uid),
      ),
    );
  }

  Future<void> _leave() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => GameDialog(
        icon: const Icon(Icons.logout_rounded),
        title: Text(context.l10n.leaveJajan),
        content: Text(context.l10n.leaveHint),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.back),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.leaveJajan),
          ),
        ],
      ),
    );
    if (!mounted || yes != true) return;
    final left = await c.leave();
    if (mounted && left) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.leaveSuccess)));
      Navigator.pop(context);
    }
  }

  Future<void> _cancel() async {
    if (c.cancelling) return;
    final agreed =
        c.cancellationStarted ||
        c.event?.state == 'CANCELLING' ||
        await showDialog<bool>(
              context: context,
              builder: (context) => GameDialog(
                icon: const Icon(Icons.event_busy_rounded),
                title: Text(context.l10n.eventCancelTitle),
                content: Text(context.l10n.eventCancelWarning),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(context.l10n.eventKeep),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(context.l10n.eventCancel),
                  ),
                ],
              ),
            ) ==
            true;
    if (!mounted || !agreed) return;
    final complete = await c.cancel();
    if (!mounted || !complete) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.eventCancelled)));
      Navigator.pop(context);
    });
  }

  Widget _stat(IconData icon, String text) => Container(
    margin: const EdgeInsets.symmetric(vertical: 3),
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: icon == Icons.timer_rounded
          ? const Color(0xFFFFEAC1)
          : const Color(0xFFF0F5F1),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFDCE5DF)),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 21, color: WelcomePalette.navy),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: WelcomePalette.navy,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (context, _) {
      final l = context.l10n;
      if (c.cancellationStarted) {
        return PopScope(
          canPop: !c.cancelling,
          child: EventDetailsShell(
            accent: const Color(0xFFFFD8B0),
            icon: Icons.hourglass_top_rounded,
            title: l.eventCancel,
            subtitle: l.eventCancellationDetails,
            badge: l.eventDetails,
            onBack: c.cancelling ? null : () => Navigator.pop(context),
            children: [
              if (c.cancelling) ...[
                const LinearProgressIndicator(),
                const SizedBox(height: 16),
                Semantics(liveRegion: true, child: Text(l.eventCleaningUp)),
              ] else if (c.cancellationComplete)
                Text(l.eventCancelled)
              else ...[
                if (c.actionError != null)
                  AuthMessage(text: l.message(c.actionError!), isError: true),
                if (c.event?.state == 'CANCELLING') ...[
                  Text(l.eventCancellationNotice),
                  const SizedBox(height: 16),
                ],
                AuthAction(label: l.retry, onPressed: _cancel),
              ],
            ],
          ),
        );
      }
      final demo = widget.marker.isDemo;
      final event = c.event;
      final marker = event?.toMap() ?? widget.marker;
      final name =
          event?.creatorName ??
          (c.isOwner ? widget.ownerName : null) ??
          l.foodie;
      final number = NumberFormat(
        '0.#',
        Localizations.localeOf(context).languageCode,
      );
      final clock = NumberFormat(
        '00',
        Localizations.localeOf(context).languageCode,
      );
      final expired = event != null && c.secondsLeft == 0;
      final closing = event?.state == 'CANCELLING';
      return EventDetailsShell(
        accent: foodColor(marker.kind),
        icon: foodIcon(marker.kind),
        title: demo
            ? mapEventTitle(context, marker)
            : c.isOwner
            ? l.eventYourJajan
            : l.eventOwnerHungry(name),
        subtitle: demo ? l.homeDemoDetails : l.eventIntro,
        badge: demo
            ? l.homeDemo
            : closing
            ? l.eventCancellationPending
            : event?.state == 'COMPLETED'
            ? l.eventCompleteTitle
            : expired
            ? l.eventExpired
            : l.eventDetails,
        onBack: () => Navigator.pop(context),
        primaryActions: [
          if (!demo && event != null && !c.isOwner && !c.isMember) ...[
            const SizedBox(height: 12),
            AuthAction(
              label: closing
                  ? l.eventClosed
                  : c.requestStatus == 'ACCEPTED'
                  ? (event!.isPublic ? l.jajanJoined : l.requestAccepted)
                  : c.requestStatus == 'REJECTED'
                  ? l.requestRejected
                  : c.sent
                  ? l.eventRequestSent
                  : c.isMember
                  ? l.eventAlreadyMember
                  : expired
                  ? l.eventExpired
                  : event!.state != 'OPEN'
                  ? l.eventClosed
                  : event.memberCount >= event.capacity
                  ? l.eventFull
                  : (event.isPublic ? l.eventJoin : l.jajanRequestJoin),
              busy: c.busy,
              onPressed: c.canJoin ? _join : null,
            ),
          ],
          if (demo) ...[
            const SizedBox(height: 12),
            AuthAction(label: l.eventJoin, onPressed: null),
          ],
          if (c.confirmed && c.isMember && !closing) ...[
            const SizedBox(height: 12),
            AuthAction(
              label: l.chatOpen,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => GangChatView(eventId: c.id, uid: c.uid),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (c.confirmed && c.isMember && event?.state == 'COMPLETED')
            AuthAction(
              label: l.eventCompleteTitle,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => JajanCompleteView(event: event!),
                ),
              ),
            ),
          if (c.isOwner &&
              c.confirmed &&
              event!.isActive &&
              ['DESTINATION_SELECTED', 'ON_THE_WAY'].contains(event.state))
            AuthAction(
              label: event.state == 'DESTINATION_SELECTED'
                  ? l.eventStartTrip
                  : l.eventCompleteAction,
              busy: c.progressing,
              onPressed: c.cancelling || c.progressing
                  ? null
                  : () async {
                      final target = event.state == 'DESTINATION_SELECTED'
                          ? 'ON_THE_WAY'
                          : 'COMPLETED';
                      await c.advance(target);
                      if (mounted &&
                          c.actionError == null &&
                          target == 'COMPLETED') {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => JajanCompleteView(event: event),
                          ),
                        );
                      }
                    },
            ),
        ],
        children: [
          if (c.actionError != null)
            AuthMessage(text: l.message(c.actionError!), isError: true),
          if (closing) Text(l.eventCancellationNotice),
          if (!demo && c.loading) const LinearProgressIndicator(),
          if (c.error != null) ...[
            AuthMessage(text: l.message(c.error!), isError: true),
            TextButton(
              onPressed: c.busy ? null : c.start,
              child: Text(l.retry),
            ),
          ],
          if (demo || event != null) ...[
            if (!demo)
              Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: WelcomePalette.navy,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: foodColor(marker.kind),
                        shape: BoxShape.circle,
                      ),
                      child: CharacterAvatar(
                        avatarId:
                            event?.creatorAvatarId ??
                            (c.isOwner ? widget.ownerAvatarId : null),
                        size: 42,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.eventHost,
                            style: const TextStyle(
                              color: WelcomePalette.gold,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.restaurant_rounded,
                      color: WelcomePalette.gold,
                      size: 22,
                    ),
                  ],
                ),
              ),
            if (event?.scheduledAt != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: JajanScheduleBadge(time: event!.scheduledAt),
              ),
            if (event != null && event.description.isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE6A3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: WelcomePalette.navy, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.notes_rounded,
                          color: WelcomePalette.navy,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l.eventDescription,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: WelcomePalette.navy,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      event.description,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                        color: WelcomePalette.navy,
                      ),
                    ),
                  ],
                ),
              ),
            if (event?.state == 'ON_THE_WAY')
              _stat(Icons.directions_walk_rounded, l.eventGoing),
            if (event?.state == 'COMPLETED')
              _stat(Icons.celebration_rounded, l.eventCompleteTitle),
            _stat(Icons.restaurant_rounded, mapEventTitle(context, marker)),
            _stat(
              Icons.groups_rounded,
              l.jajanMemberCount(marker.members, marker.capacity),
            ),
            _stat(
              Icons.near_me_rounded,
              widget.area.isFallback
                  ? l.eventDistanceUnavailable
                  : marker.distanceKm(widget.area) < 1
                  ? l.eventSameArea
                  : l.homeDistance(
                      number.format(marker.distanceKm(widget.area)),
                    ),
            ),
            Text(
              l.eventAreaPrivacy,
              style: const TextStyle(fontSize: 12, color: Color(0xFF53736F)),
            ),
            if (widget.area.isFallback)
              TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.my_location_rounded),
                label: Text(l.locationFixOnMap),
              ),
            if (!demo) ...[
              const SizedBox(height: 12),
              if (event?.state != 'COMPLETED')
                _stat(
                  Icons.timer_rounded,
                  expired
                      ? l.eventExpired
                      : event?.scheduledAt != null && c.secondsLeft > 2700
                      ? l.jajanExpiresOn(
                          jajanScheduleTime(context, event!.expiresAt),
                        )
                      : l.eventTimeLeft(
                          clock.format(c.secondsLeft ~/ 60),
                          clock.format(c.secondsLeft % 60),
                        ),
                ),
              if (!expired && !closing && event!.state == 'DECIDING')
                AuthMessage(text: l.eventClosed),
              const SizedBox(height: 10),
              if (c.confirmed && !closing)
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFB5EFD8),
                    foregroundColor: WelcomePalette.navy,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                    side: const BorderSide(
                      color: WelcomePalette.navy,
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EventMembersView(eventId: c.id),
                    ),
                  ),
                  icon: const Icon(Icons.groups_rounded),
                  label: Text(l.eventViewMembers),
                ),
              if (event != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: _stat(
                    event.isPublic
                        ? Icons.public_rounded
                        : Icons.lock_outline_rounded,
                    event.isPublic ? l.jajanPublicHint : l.jajanPrivateHint,
                  ),
                ),
              if (c.confirmed &&
                  c.isMember &&
                  !c.isOwner &&
                  event!.isActive &&
                  !closing)
                OutlinedButton.icon(
                  onPressed: c.busy ? null : _leave,
                  icon: const Icon(Icons.exit_to_app_rounded),
                  label: Text(l.leaveJajan),
                ),
              if (c.isOwner) ...[
                if (c.confirmed &&
                    event!.isActive &&
                    event.state == 'OPEN' &&
                    !closing) ...[
                  OutlinedButton.icon(
                    onPressed: c.cancelling
                        ? null
                        : () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  InviteFriendsView(uid: c.uid, eventId: c.id),
                            ),
                          ),
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                    label: Text(l.inviteFriends),
                  ),
                  const SizedBox(height: 12),
                ],
                if (event?.isPublic != true) ...[
                  if (c.requestCount != null)
                    Text(
                      l.eventRequestCount(c.requestCount!),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  if (c.requestsLoading) const LinearProgressIndicator(),
                  if (c.requestsError != null)
                    AuthMessage(
                      text: l.message(c.requestsError!),
                      isError: true,
                    ),
                  const SizedBox(height: 12),
                  AuthAction(
                    label: l.eventViewRequests,
                    onPressed: closing || c.cancelling ? null : _requests,
                  ),
                  const SizedBox(height: 12),
                ],
                TextButton.icon(
                  onPressed: c.cancelling || c.decidingUid != null
                      ? null
                      : _cancel,
                  icon: const Icon(Icons.delete_forever_rounded),
                  label: Text(
                    closing ? l.eventFinishCancellation : l.eventCancel,
                  ),
                ),
              ] else ...[
                const SizedBox(height: 12),
                if (c.sent && !closing)
                  AuthMessage(
                    text: c.requestStatus == 'ACCEPTED'
                        ? (event!.isPublic
                              ? l.jajanJoined
                              : l.requestAcceptedMessage)
                        : c.requestStatus == 'REJECTED'
                        ? l.requestRejectedMessage
                        : l.eventRequestExplanation,
                  ),
              ],
            ],
          ],
        ],
      );
    },
  );
}
