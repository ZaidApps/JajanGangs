# Phase 4: Jajan event details

Phase 5 extends these historical notes with accept/reject, cancellation and active-event enforcement. Follow [Phase 5 rollout](phase5-join-requests.md) for current rules and migration requirements.

Tap a map marker or the Event Details button beneath the selected event. Only real Firestore events appear on the signed-in map. An empty result shows a localized empty state and Create Jajan / refresh actions. Loading, query failure and missing location have distinct states. The page shows the host's name and character, craving, participants/capacity (including the host), approximate distance and a local countdown to server-created time + 45 minutes. Same-area events use an area label instead of pretending to have precise distance. Preview-location distances are unavailable.

The game-themed page supports English and Indonesian. Event and own-request document listeners exist only while the page is open and are disposed with its controller. The countdown uses a local timer, not repeated database reads. Cached details cannot enable joining before a server-confirmed read. Rules enforce expiry using server time regardless of device clock.

## Required Firebase setup

The local files are ready but have **not been deployed**. Publish the complete root `firestore.rules` file in Firebase Console > Firestore Database > Rules. Do not append it to the previous rules.

In Firestore > Indexes, choose **Create structured index**, then create the following composite indexes. Choose **Collection** query scope for both (including the subcollection named `join_requests`). Leave the existing creatorId / createdAt index in place.

| Collection ID | Fields in order |
| --- | --- |
| `jajan_events` | `visibility` Ascending, `state` Ascending, `area.latCell` Ascending, `area.lngCell` Ascending, `createdAt` Descending |
| `join_requests` | `status` Ascending, `createdAt` Ascending |

Wait until both indexes are enabled. The same definitions are in root `firestore.indexes.json`. If Firebase CLI is configured, the equivalent command is:

```sh
firebase deploy --only firestore:rules,firestore:indexes --project jajangangs
```

Firestore requires composite indexes for these compound queries; see [Firebase's index documentation](https://firebase.google.com/docs/firestore/query-data/indexing). Owner request totals use a server count aggregation, with the same owner-only access rules as the list; see [Firebase's aggregation documentation](https://firebase.google.com/docs/firestore/query-data/aggregation-queries).

## Discovery and privacy

- New events explicitly store `visibility: public`, plus `creatorName` and `creatorAvatarId` snapshots checked against the creator's private profile by rules. The create form explains what is shared. Private user documents remain unreadable by other users.
- Earlier events without public visibility remain creator-only. No migration or public exposure of old events is performed. Create a new event after deploying the rules to make it discoverable.
- Nearby discovery searches the current rounded cell and its eight neighbors. It runs three bounded queries (up to 20 results each), filtering OPEN public events created within the last 45 minutes. This is a small surrounding grid, not an exhaustive radius search. Dense areas can have more events than the initial bounded result set.
- Discovery runs after obtaining an approximate area, after creating/returning from a real event, and on map refresh. Camera movement does not query Firestore. No discovery query runs for the Jakarta fallback location.
- Public visibility allows verified users to read public event documents; the nearby grid is a discovery filter, not a location-based authorization boundary. Friends and gang visibility remain future work.
- Only rounded area cells and uncertainty radius are stored; no precise location or contact details are added.

## Requests

`jajan_events/{eventId}/join_requests/{requesterUid}` stores `userId`, display `name`, `avatarId`, `status: PENDING`, and server `createdAt`.

The requester can read only their own request. Only the event owner can read the request list and count. New requests require a verified user with a profile, a public OPEN unexpired event, available capacity, and a requester who is neither owner nor member. Clients cannot update or delete requests or alter participant counts in this phase.

Requests use a transaction and deterministic UID document ID, so retries and concurrent taps cannot create duplicates. A pending request does not reserve a seat or increment the participant count. Acceptance/rejection, notifications and chat remain the next phase.

Owner counts and the first 20 pending requests load on entry. View Requests refreshes them; its refresh and Load more controls fetch additional data on demand. Counts are not live subscriptions. The event document and the requester's own request are live while details is open. Expired/full events disable new joins; a sent request remains visible after expiry.

## Validation boundary

Source review, localization generation and Dart formatting only. No tests, analyzer, build, emulator/device run, Firebase deployment or real request submission was performed, per the user's preference. Runtime and rules behavior remain unverified.

## Location recovery and empty maps

The signed-in Home controller no longer injects demo markers. Selection is nullable and the Mapbox renderer skips the selected-marker halo when there are no events, including after the last event expires. The Create Jajan and Gang actions remain accessible.

Home shows location failures directly, with separate messages for disabled services, denied/blocked permission, timeout and unavailable position. Find my area retries while showing progress. Settings opens app settings for permission failures or location settings for service/timeout failures; returning from a successfully opened settings screen triggers a new lookup. If settings cannot open, a localized manual instruction is shown. The location sheet updates while lookup runs. The recenter button requests location when only the preview area is available.

The location service shares concurrent requests across Home/Create, uses balanced accuracy with a 45-second fix deadline, and rechecks service/permission status after a failed fix. Android still requests approximate location only. No raw position is logged, stored or sent; debug failure output contains only a stable reason key or exception type. Coarse fixes can be slow on Android; see the [geolocator documentation](https://pub.dev/packages/geolocator). This change does not guarantee a fix when the device cannot provide one.

No Firestore rule/index changes are needed for this follow-up. Previous Phase 4 deployment requirements still apply. No tests, analyzer, builds or device runs were performed.
