# Phase 5: join requests, cancellation and one active event

Phase 6 extends this with member-only gang chat and message cleanup. See [Phase 6 setup](phase6-gang-chat.md) for the current additional rules, index, and notification deployment steps.

## App behavior

- **Create Jajan** checks the server before opening the form. If the owner has an active event, a localized dialog appears on the current map: “You already have an active Jajan. Complete or cancel it, or wait for it to expire before creating another.” No navigation to the existing event occurs. Network failure keeps the form closed and offers retry by tapping again.
- The save transaction also reads/writes the owner's `active_jajan_slots/{uid}` document. Rules require the slot and new event to agree and reject replacing an active reservation. Concurrent devices cannot create separate active events once the rollout below is complete.
- OPEN, DECIDING, DESTINATION_SELECTED and ON_THE_WAY block creation until expiry. COMPLETED and CANCELLING do not. Completion UI/state progression is a future phase; cancellation and the existing 45-minute expiry work now.
- Owner **View Requests** opens a dedicated game-themed page with names, character avatars, Accept and Reject. Requests use `REQUESTED`, `ACCEPTED`, `REJECTED`. Legacy `PENDING` is treated as REQUESTED without bulk rewriting request data.
- Acceptance writes the decision, member IDs and member count in one transaction. Rules enforce the matching request transition, unique membership, active OPEN state, server-time expiry and capacity. Reject changes only the decision. Retries of the same decision do not add a duplicate member; opposing decisions cannot overwrite a terminal state.
- Requesters see accepted/rejected status on their details page through the existing own-request listener. Rejected requests cannot be resubmitted to the same event in this phase.
- Names are real stored display names; no fictional requester messages are inserted. English and Indonesian cover all new UI, errors, loading states and confirmation text.

## Cancellation and recovery

Only the owner can cancel, including an event with accepted members. A permanent-deletion confirmation appears first. The cancellation transaction marks the parent CANCELLING and releases its active slot before cleanup. Rules then deny joins and decisions, and discovery excludes the event.

Cleanup deletes **all** documents under `jajan_events/{id}/join_requests` in bounded batches, including accepted and rejected requests. It deletes the parent last; the parent contains all current membership data. No separate event-members/chat/votes collections exist in this phase. A per-user empty active slot may remain, but it contains no reference to the canceled event. User profiles are not deleted.

Cleanup uses batches of 10 requests and retries temporary failures up to three attempts per stage within the same cancellation action. The screen stays in progress until a server read confirms the parent is deleted; CANCELLING alone never displays success. A persistent failure offers Retry and debug logging records the operation stage and Firebase error code. These changes require no additional rules or indexes.

Event details treat the initial cached snapshot as loading, including an initial cache miss. Joining stays disabled until server confirmation. Connection errors appear only after a stream failure or a 15-second confirmation timeout, rather than flashing on every opening.

If the network drops or the app closes, the CANCELLING parent is the durable recovery record. The details screen provides Finish cancellation, and Home resumes unfinished cancellations on entry with a retry action after failure. A completed cancellation removes the parent as well. Cleanup runs on the owner's connected app, **not on a background server**: if every owner device remains closed/offline, deletion waits until one reconnects and resumes. Future chat/vote subcollections must be added to cleanup when introduced.

Firestore does not cascade parent deletion to subcollections; explicit cleanup is intentional. Atomic rules use `getAfter` to require coupled changes. See [Firebase transaction documentation](https://firebase.google.com/docs/firestore/manage-data/transactions) and [Firestore rule conditions](https://firebase.google.com/docs/firestore/security/rules-conditions).

## Firebase rollout — required before using Phase 5

For the current development project, the user chose to skip migration. Publish the final `firestore.rules` and enable the indexes below; cancel or let older development events expire. The migration options below are only for a deployment that needs to preserve active events from before Phase 5.

These files have **not** been published or run against your project. Do not publish the final rules alone while unregistered older events are still active: Firestore rules cannot query all of an owner's arbitrary event IDs to discover legacy events.

1. Add this composite index in Firebase Console > Firestore > Indexes > **Create structured index**. Collection ID: **jajan_events**; query scope: **Collection**; fields **creatorId Ascending**, **state Ascending**. Keep the earlier indexes, including `join_requests: status Ascending, createdAt Ascending`. Wait for Enabled.
2. Briefly pause app writes by publishing the complete `firestore.phase5-migration.rules` in the Rules tab. This preserves private read restrictions but temporarily blocks all client writes, including registration/profile changes. Wait for publication to complete before proceeding. Admin jobs that create events must also remain paused.
3. Choose **one** transition below, then publish the complete final `firestore.rules` to reopen writes.

### Option A: preserve currently active events immediately

Use the provided admin migration, authenticated to **jajangangs** with Application Default Credentials authorized to administer Firestore. Firebase mobile configuration files are not admin credentials. Keep credentials outside the repository.

From the project root:

```powershell
npm install --prefix tool/phase5-migration
node tool/phase5-migration/migrate.mjs --project=jajangangs
node tool/phase5-migration/migrate.mjs --project=jajangangs --apply --writes-frozen
```

The first run is a dry run; the second creates legacy reservations. It uses Firestore's read timestamp, scans existing events in pages, writes no event/request changes, and refuses to overwrite conflicting slots. It logs counts, not names or locations. If it fails, keep writes frozen, resolve the issue and rerun; completed compatible records are preserved.

For owners with multiple older active events, all IDs are reserved. Canceling the last legacy event releases that reservation immediately; otherwise the conservative reservation lasts until the latest original legacy expiry. This temporary transition constraint lasts at most the existing 45-minute event lifetime. It avoids accidentally bypassing another older active event.

After successful migration, publish **firestore.rules**. Older apps that omit the new atomic slot write will no longer be able to create events; use the updated app.

### Option B: simple rollout without admin tooling

After the temporary read-only rules have finished publishing, leave client writes frozen for **at least 46 minutes**. All pre-Phase-5 events have a fixed 45-minute lifetime, so their active periods will have ended. Then publish **firestore.rules**. No migration script is needed. This option is suitable for the current MVP only; reconsider it once extensions or different lifetimes exist.

The final rules and all indexes can alternatively be deployed using an already configured Firebase CLI after completing the transition:

```powershell
firebase deploy --only firestore:rules,firestore:indexes --project jajangangs
```

## Data changes

- `active_jajan_slots/{uid}`: `eventId`, `legacyEventIds`, `legacyUntil`. Owner-only reads, no client list/delete. Ordinary creation preserves migration fields. Cancellation can release only an event whose cancellation is proved in the same atomic write.
- `join_requests/{uid}` adds `decidedAt` on decision; existing immutable requester identity/profile snapshot and `createdAt` are retained.
- Event acceptance adds `lastAcceptedUid`, which lets rules match an increment to the exact request being accepted. Cancellation deletes it along with the parent.

## Validation boundary

Source review, Dart formatting and localization generation only. No tests, analyzer, build, device run, migration, Firebase deployment or real database mutation was performed. Runtime behavior and security rules remain unverified, per the user's no-testing instruction.
