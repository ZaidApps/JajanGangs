# Phase 8 — In-chat voting and host request notifications

## App behavior

- A scrollable voting card appears inside the gang chat. Only the host can create a poll, with 2–5 manually entered, distinct destination names (up to 60 characters). Food search remains deferred.
- One poll exists per event. Creation changes the event from `OPEN` to `DECIDING`. New join requests and acceptance stop at this point; the host should handle pending requests before starting the poll.
- Accepted members and the host can tap an option to vote, or change their vote while the poll is open. Counts, progress bars, and the member's own selected option update through one document listener.
- The host finishes voting with at least one vote. They confirm the leading destination, or choose among tied leaders. A transaction checks the current results again; a choice that is no longer a leader is rejected with localized feedback.
- Closing the poll atomically changes the event to `DESTINATION_SELECTED`. The chat shows the winning name and a celebration heading. Voting is then immutable.
- The original 45-minute expiry still applies. Expired events cannot start, change, or finish polls. Members can read existing results. Polls do not extend events automatically.
- A new join request atomically creates an in-app notification addressed to the host, with the requester's profile name. Tapping it opens the event's requests screen. Retries reuse the request/notification IDs and do not create duplicates. Already-existing requests do not receive retroactive notifications.
- The existing latest-10 notification feed and English/Bahasa Indonesia localization remain in use. No OS push or Cloud Functions are introduced.

## Firebase setup

**Publish the complete updated root `firestore.rules` before using this app version.** In Firebase Console → Firestore Database → Rules, replace the editor contents with the file and click Publish. Existing older app versions cannot submit new join requests under these rules because they do not write the required host notification.

**No new index is needed for Phase 8.** Keep the existing notification collection-group index: `event_notifications`, `recipientIds` Array contains, `createdAt` Descending. Voting reads a known document directly. Existing request-list indexes remain required.

Data lives under `jajan_events/{eventId}/polls/current`. Five bounded voter lists represent up to five choices; security rules allow a member to move only their own UID between lists. The host cannot modify other members' votes or select a losing destination. Poll/event transitions must be committed together. Only accepted members can read poll data.

Cancellation cleanup now includes `polls`, before the parent event is deleted. No migration or billing upgrade is required. See [Spark setup](spark-setup.md).

## Review boundary

Dart formatting, localization generation, and source review only. No tests, analyzer, builds, device runs, Firebase deployment, or live data changes were performed. Runtime behavior and rule deployment remain unverified.
