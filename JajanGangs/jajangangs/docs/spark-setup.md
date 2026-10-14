# Spark setup — current development configuration

All current and upcoming phases target Firebase Spark. Chat, membership, unread indicators, and in-app notifications use Firestore directly, within Spark quotas. Cloud Functions and OS push delivery are deferred. The app does not register device tokens or request notification permission.

Phase 8 adds [in-chat voting and host join-request notifications](phase8-voting.md). Publish the latest rules; it requires no additional index beyond those below. Cancellation also removes the event's `polls` collection.

The [Friends setup guide](friends-setup.md) covers friend requests and the three additional `friends` indexes. Publish the latest rules before using that feature.

## Publish before using this app version

1. In Firebase Console → Firestore Database → Rules, replace the editor contents with the complete root `firestore.rules`, then Publish. These rules and the updated app must be used together: message sends and request decisions now require their notification records in the same transaction.
2. In Firestore → Indexes → Create index, choose **Create structured index**, then configure:

   | Setting | Value |
   | --- | --- |
   | Collection ID | `event_notifications` |
   | Field 1 | `recipientIds` — Array contains |
   | Field 2 | `createdAt` — Descending |
   | Query scope | Collection group |

   Wait until the index is enabled. This replaces the previous `recipientId` ascending definition. An existing old index can remain temporarily; the app no longer queries that field.
3. Keep the existing `jajan_events` index with `memberIds` Array contains and `createdAt` Descending, query scope **Collection**. All required index definitions are in root `firestore.indexes.json`.

Alternatively, deploy the local rules and indexes using the Firebase CLI from the project directory:

```powershell
firebase deploy --only firestore:rules,firestore:indexes --project jajangangs
```

No functions deployment, npm installation, or billing upgrade is needed. `firebase.json` no longer includes a functions deployment target. The old source under `functions/` is deferred reference code, incompatible with the current notification schema. If those functions were previously deployed on a billed project, disable/delete their deployments before using this version; removing local configuration does not remove remote functions.

## Behavior

- Messages appear immediately, with a pending indicator, a confirmation checkmark after the write succeeds, or a red failure bubble with retry. The checkmark confirms storage, not recipient delivery/read status.
- Every send atomically writes the message, one private shared `chat_summary/latest`, and one grouped message notification. This is three writes regardless of gang size. Rules validate the matching new message and membership.
- Accept/reject transactions also write a notification for the requester. No server trigger is involved.
- The bell displays the newest 10 entries. Message notifications are grouped by event; a newer message replaces that event's previous message alert. Each recipient acknowledges a specific version through `readBy`, without changing another user's acknowledgement.
- Each member has a private `chat_state` read cursor. Inbox rows watch that cursor and the shared private summary. Covered or backgrounded chats do not mark messages read. Inbox pagination remains independent of the notification limit.
- Notifications update in the app through Firestore listeners. There are no OS banners while the app is closed or in the background; stored activity appears when the app reconnects. No notification permission is needed.
- Cancellation removes requests, messages, read cursors, summaries, and notification records before deleting the event. Client cleanup still needs the owner's app to complete or resume it. Expiry prevents new sends but does not schedule automatic data deletion on Spark.
- Older notification documents using `recipientId` do not appear in the new query. New actions create the new records. Existing chats without a summary use a latest-message preview fallback; no data migration is required for development.
- All interface copy remains localized in English and Bahasa Indonesia. Future app text must follow `lib/AGENTS.md`; future backend work must follow the Spark constraint in root `AGENTS.md`.

## Verification boundary

Only dependency resolution, formatting, and source review were performed. No tests, analyzer, builds, device runs, Firebase deployment, billing changes, or live database modifications were performed. Rules and runtime behavior still require verification when testing is authorized.
