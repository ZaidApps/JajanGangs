import 'dart:async';

import 'package:flutter/material.dart';

import '../controllers/event_details_controller.dart';
import '../l10n/l10n.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/character_avatar.dart';
import '../widgets/welcome_game_elements.dart';

class JoinRequestsView extends StatefulWidget {
  const JoinRequestsView({super.key, required this.controller});
  // The details route owns/disposes the controller and its event listener.
  final EventDetailsController controller;
  @override
  State<JoinRequestsView> createState() => _JoinRequestsViewState();
}

class _JoinRequestsViewState extends State<JoinRequestsView> {
  @override
  void initState() {
    super.initState();
    unawaited(widget.controller.loadRequests());
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final c = widget.controller;
      final l = context.l10n;
      final stopped =
          (c.confirmed && c.event == null) || c.event?.state == 'CANCELLING';
      return AuthScaffold(
        title: l.requestsTitle,
        subtitle: l.requestsSubtitle,
        badge: l.eventViewRequests,
        onBack: () => Navigator.pop(context),
        children: [
          if (c.loading) const LinearProgressIndicator(),
          if (c.error != null)
            AuthMessage(text: l.message(c.error!), isError: true),
          if (stopped && c.error == null) Text(l.eventCancellationNotice),
          if (!stopped && c.confirmed && !c.canDecide && c.decidingUid == null)
            Text(l.eventClosed),
          if (c.actionError != null)
            AuthMessage(text: l.message(c.actionError!), isError: true),
          if (c.requestsError != null)
            AuthMessage(text: l.message(c.requestsError!), isError: true),
          if (c.requestsLoading) const LinearProgressIndicator(),
          if (!stopped) ...[
            TextButton.icon(
              onPressed: c.requestsLoading || c.decidingUid != null
                  ? null
                  : () => c.loadRequests(),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l.eventRefresh),
            ),
            if (c.requestCount != null)
              Text(
                l.eventRequestCount(c.requestCount!),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            if (!c.requestsLoading &&
                c.requestsError == null &&
                c.pending.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(l.eventNoRequests),
              ),
            for (final request in c.pending)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: WelcomePalette.navy, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        CharacterAvatar(
                          avatarId: request['avatarId'] as String?,
                          size: 54,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            request['name'] as String? ?? l.foodie,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (c.decidingUid == request['userId'])
                      const LinearProgressIndicator(),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed:
                              c.canDecide &&
                                  !c.requestsLoading &&
                                  c.event!.memberCount < c.event!.capacity
                              ? () => c.decide(
                                  request['userId'] as String,
                                  accept: true,
                                )
                              : null,
                          icon: const Icon(Icons.check_rounded),
                          label: Text(l.requestAccept),
                        ),
                        OutlinedButton.icon(
                          onPressed: c.canDecide && !c.requestsLoading
                              ? () => c.decide(
                                  request['userId'] as String,
                                  accept: false,
                                )
                              : null,
                          icon: const Icon(Icons.close_rounded),
                          label: Text(l.requestReject),
                        ),
                      ],
                    ),
                    if (c.event != null &&
                        c.event!.memberCount >= c.event!.capacity)
                      Text(l.eventFull),
                  ],
                ),
              ),
            if (c.hasMore)
              TextButton(
                onPressed: c.requestsLoading || c.decidingUid != null
                    ? null
                    : () => c.loadRequests(more: true),
                child: Text(l.eventLoadMore),
              ),
          ],
        ],
      );
    },
  );
}
