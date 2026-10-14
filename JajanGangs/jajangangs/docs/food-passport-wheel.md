# Food Passport and food wheel

## Firebase setup

Publish the updated root `firestore.rules` and deploy the indexes in `firestore.indexes.json`.
No Cloud Functions, Storage uploads, new dependencies, or billing-dependent services are required.

New composite index (keep all existing indexes):

| Collection ID | Query scope | Fields |
| --- | --- | --- |
| `food_memories` | Collection | `visibility` Ascending, `createdAt` Descending |

In Firebase Console: Firestore Database → Indexes → Add index → Structured index.
Use the collection ID and fields above, choose Collection scope, and wait for Enabled.
In the Rules tab, replace the rules with the contents of the root rules file and publish.

## Food Passport

- Home → Profile → Food Passport. Accepted friend profile → Food Passport shows only shared entries.
- Restaurant and dish: 1–80 characters each. Optional area/neighborhood: up to 80 characters; older entries without an area remain supported. Custom dumpling rating: 1–5. Optional review: 200 characters.
- Visit date, Would eat again, and per-entry Only me / My friends visibility. Default: Only me.
- Edit and delete your own entries. Deletion requires confirmation.
- Completion screen offers Add a food memory; a closed destination poll prefills the restaurant field when available. It remains editable.
- Preset food illustrations; no photo uploads.
- Entries: `users/{uid}/food_memories/{id}`. Friend access is checked against the accepted friendship in security rules, not just the UI.
- Server reads, 20 entries per page, explicit refresh. Summary counts describe the entries currently loaded, not lifetime totals. Places are compared using trimmed, case-insensitive names.
- Calendar dates are stored at UTC midnight to preserve the chosen date across time zones.

## Food wheel

- Any accepted member, including the host, can create a wheel from the activity menu beside Send in an active event's chat.
- One active wheel per event; one contribution per member, locked after Submit. Food name: 1–40 characters.
- At least two members must contribute. Only that wheel's creator can spin. Others need not participate.
- Each contribution has equal probability. Duplicate food names are allowed, so two members choosing the same food give it two slices.
- Transaction freezes choices and persists the winner before animation. Retrying a completed spin never changes its winner.
- Every viewer reads the same result; devices animate when they observe an open round becoming closed. Reopening a finished round displays its saved result immediately.
- Colorful slices, member avatars, celebration particles, optional vibration (off by default), and reduced-motion support.
- A wheel is a suggestion only. It does not change event status or the host's destination poll.
- A completed wheel may be followed by a new round created by any accepted member.
- Current round: `jajan_events/{id}/wheels/current`. A new round archives the previous result atomically under `wheel_history/{roundId}`. History UI shows the latest 10 archived rounds; the current result remains in the main card.
- Cancellation cleanup deletes both collections before deleting the event. Expiry/completion stops new contributions and spins; results remain readable with chat history.
- Client-generated randomness is suitable for casual food choices, not a tamper-proof prize draw. Rules enforce permissions, valid choices, and immutable completed results; they cannot prove random selection.

All app-owned strings support English and Bahasa Indonesia. User-written food names and reviews retain their original language.

## Validation boundary

Source reviewed, formatted, and localization accessors generated. No tests, analyzer, builds, device runs, or Firebase deployment were performed, as requested.

Chat activity menu asks before creating a vote or wheel. Posted activities appear as expandable chat cards for members. Destination votes remain host-created; wheels can be created by any accepted member. No new index is needed for the optional area field; publish the updated rules.
