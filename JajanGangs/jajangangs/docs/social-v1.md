# Discovery cards, invitations, leaving, blocking and reports

## Setup

Publish the complete root `firestore.rules` file in Firebase Console → Firestore → Rules. These client transactions depend on the updated rules. No new composite indexes are needed: invitations use the existing recipientIds/createdAt notification collection-group index, and the picker uses the existing accepted-friends query/index. Blocked accounts use document-ID pagination.

No Cloud Functions, paid backend, or automatic device push was introduced. The existing manual announcement topic is unchanged. No private one-to-one messaging was added.

## Discovery

The horizontal cards use `HomeController.events`, the exact collection used by map markers. Creator name and description are carried through `JajanEvent.toMap()` from already-loaded documents. Rendering, scrolling and rebuilding the list add no Firestore reads/listeners and no place-search requests. Tapping a card opens the existing event-details flow, which has its existing live reads and return refresh; this is the same behavior as tapping a marker.

## Invite friends

Hosts can open **Invite friends** from an active OPEN event's details. The picker reads accepted friends, 20 at a time, only while open. Each invite is a transaction checking the event, friendship and both block directions. It writes `jajan_events/{eventId}/event_notifications/invite_{recipientUid}` once per event/recipient. Retries reuse that ID and do not resend an existing invitation. Opening the picker again may show Invite until pressed; the transaction recognizes an already-sent invitation without another write.

Recipients see the invitation in the existing latest-10 in-app notification list. Tapping opens event details. Invitations never bypass capacity, expiry, or private-event approval. Full/non-OPEN events cannot issue new invitations. Existing notifications can remain after friendship removal/blocking; new invitations are prevented. Cancellation's existing notification cleanup includes invitations.

## Leave Jajan

Non-host members can leave an active event from details, with confirmation. Chat now has an event-details shortcut, so this is accessible after the event stops appearing in discovery. A transaction removes only the authenticated member from `memberIds`, decrements the count, and deletes their accepted join-request document. Rules require both changes atomically. Existing membership checks revoke chat access and the inbox membership query removes the chat.

Hosts continue to cancel/delete the entire event. Former members may join again only if the usual event state/capacity rules allow it; private events require a new request. Messages, submitted votes and wheel choices remain historical contributions. The host can spin an unfinished wheel if its initiator has left. Contributions remain bounded by the existing 12-choice wheel limit.

## Block and unblock

Member/friend profiles expose Block and Report. Blocking writes `users/{uid}/blocks/{peer}` and removes both friendship records atomically, including any pending request notification. Both directions are checked before new friendship requests, acceptance, or event invitations. The reusable `socialAllowed` rules helper and `requireUnblocked` service check should also protect future private chat.

Blocking does not eject anyone from shared events, hide existing group messages, or prevent ordinary public/private-event joining. The confirmation explains this scope. **Friends → Blocked users** lets users page through their blocks and unblock. Unblocking does not restore friendship automatically. Each endpoint can read the specific block between them, but only the owner can list their block collection or remove their own block.

## Reports: manual moderation

Reports offer spam/scam, harassment, unsafe behavior and other reasons, plus up to 500 characters of optional context. `user_reports/{randomId}` stores reporterId, targetId, reason, details, optional eventId, createdAt and status NEW. The form keeps the same ID when retrying, avoiding duplicate reports from ambiguous timeouts. A reporter can read their exact report for retry reconciliation; other app users cannot read it, and clients cannot list/update/delete reports.

Review NEW reports directly in Firebase Console. Console project administrators can update their review status or handle them manually; there is no automatic penalty, reporting dashboard or promised response time. Do not grant ordinary users Firebase Console access.

All app-owned labels/messages were added in English and Indonesian. Source review, Dart formatting and localization generation only; no tests, analyzer, builds or device runs were performed at the user's request.
