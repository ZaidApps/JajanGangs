# Create Jajan

Phase 5 adds an immediate active-event check before this form opens. See [Phase 5 rollout](phase5-join-requests.md) before deploying the new rules.

Phase 4 extends this flow with public discovery and join requests. See [Jajan event details](jajan-event-details.md) for the additional rules/index setup and current access model.

The Home Map button remains **Create Jajan**. It opens the localized **I'm Hungry!** form with Anything, Fast Food, Chicken, Pizza, Cafe and Street Food. Capacity includes the creator: 2, 3, 4, or an exact 5–12 people under 5+. Default selections are Anything and 2.

Creation requires a verified signed-in user with a profile and a usable approximate area. Jakarta preview data is not accepted. Tapping Create Jajan requests a fresh approximate area (and permission when needed) before preparing or saving a new event. The form preserves choices on location failure and offers device settings if permission is blocked or services are off. Location lookup has a 45-second timeout with retry guidance. Retrying an unresolved save reuses its original area and event ID. It never stores precise coordinates.

## Firestore setup required

1. Publish the updated root `firestore.rules` in Firebase Console > Firestore Database > Rules. Existing profile/avatar rules are preserved; event creation and creator-only reads are added.
2. Add the composite index from `firestore.indexes.json`: collection **jajan_events**, query scope **Collection**, **creatorId Ascending**, **createdAt Descending**. Wait for the index to finish building. This supports restoring your saved events after reopening the map.

If Firebase CLI is already configured for the project, the equivalent deployment is:

```sh
firebase deploy --only firestore:rules,firestore:indexes --project jajangangs
```

These console changes were not deployed automatically. Old rules reject event creation; a missing index prevents loading saved events but does not prevent the creation transaction itself.

## Stored event

Collection: `jajan_events/{randomDocumentId}`.

- `creatorId`: authenticated user's UID
- `creatorName`, `creatorAvatarId`: display-profile snapshot verified by rules
- `visibility`: public for newly created events
- `craving`: anything / fastFood / chicken / pizza / cafe / streetFood
- `capacity`: integer 2–12, including creator
- `memberIds`: initially just the creator UID
- `memberCount`: initially 1
- `state`: OPEN
- `area`: integer `latCell` and `lngCell` on a 0.02-degree grid, plus `radiusMeters` (minimum 2000). Coordinates are reconstructed as cell × 0.02.
- `createdAt`, `updatedAt`: Firestore server timestamps
- `durationMinutes`: 45

Expiry is **createdAt + 45 minutes**, derived from the trusted creation timestamp rather than a client-written expiry date. The map filters expired events on load and every 15 seconds while open. Expired documents remain stored with their original state; scheduled cleanup/state transitions and public discovery will be implemented in a later phase. Future join/state mutation rules must enforce the server-side expiry condition too.

Rules whitelist fields, cravings and numeric ranges, require ownership and initial membership, and disallow event updates/deletes in this phase. The creator can read their events; verified users can also read new public events. Legacy events remain creator-only. Verified users may read an absent document to begin an idempotent creation transaction. Phase 4 adds pending join requests; acceptance, chat and event-members remain future work.

## Save and retry behavior

A UID-scoped pending draft, containing only the event ID and coarse event parameters, is saved locally before sending the transaction. Double taps are blocked. Retry and app restart reuse the same ID; an already committed event is returned instead of duplicated. The form keeps original choices locked while a request is unresolved. Back navigation is blocked during submission but allowed after failure; the pending draft remains recoverable.

The app reports success only after reading the committed event from the server. Offline/timeout failures show retry guidance. A recovered event that has already expired is acknowledged without reappearing as active. Local drafts are removed after confirmation.

The map loads the creator's 20 most recent events on entry and performs bounded nearby event discovery once an approximate area is available. Map panning does not trigger database queries. Details pages listen only to the selected event and the viewer's own request. Only real events are displayed; an empty map offers Create Jajan and refresh actions. Sign-out disposes this user's Home controller.

No tests, analyzer, builds, device runs or real event submissions were performed, per the user's preference. Localization generation and Dart formatting were performed.
