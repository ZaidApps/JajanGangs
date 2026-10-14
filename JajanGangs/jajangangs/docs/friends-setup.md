# Friends — Spark setup

## Where to find it

- Home → profile/avatar button → **My Friends** opens Friends, Incoming, and Sent tabs.
- Open an event's **View Members**, or the member list in a gang chat. Tap another person's row to open their name/avatar card, then **Add Friend**.
- The recipient gets a notification in the existing Home bell. Tapping it opens the request with Accept/Decline actions. Incoming requests are also available in My Friends.
- A sender can cancel a pending request; either person can remove an accepted friend. A removal confirmation prevents accidental taps. Each person can see only their own friends/requests.
- Both records change together in a Firestore transaction. Crossed sends retain one pending request; the recipient must explicitly accept. Sending again while already pending/accepted is harmless. There are no friend DMs or user search in this phase.
- Names and avatars are snapshots from the user's own profile and the event's already-visible member information. No email or coordinates are added to friend records. Accepted friendships survive the source event's expiry or deletion. New requests require an existing, accessible event with the target in its member list.
- Request notifications share the existing newest-10 feed. Accepting, declining, or cancelling removes that request notification. No OS push or server function is involved.

## Required Firebase changes

1. Publish the complete updated root `firestore.rules` in Firebase Console → Firestore Database → Rules.
2. Add these **structured/composite** indexes. For all three, use collection ID **friends** and query scope **Collection**:

   | Purpose | Fields, in order |
   | --- | --- |
   | Friends | `status` Ascending, `createdAt` Descending |
   | Incoming | `status` Ascending, `toId` Ascending, `createdAt` Descending |
   | Sent | `status` Ascending, `fromId` Ascending, `createdAt` Descending |

3. Keep the existing **Collection group** index on `event_notifications`: `recipientIds` Array contains, `createdAt` Descending. It also serves friend notifications.
4. Wait for the new indexes to become Enabled before using My Friends.

All definitions are in `firestore.indexes.json`. Alternatively, deploy rules and indexes together from the project directory:

```powershell
firebase deploy --only firestore:rules,firestore:indexes --project jajangangs
```

## Data and limits

Reciprocal documents are stored at `users/{uid}/friends/{peerUid}` and `users/{peerUid}/friends/{uid}`. Rules require identical resulting data on both sides. Only the intended recipient can accept/decline, only the sender can cancel, and either friend can remove an accepted friendship.

States are `REQUESTED`, `ACCEPTED`, `DECLINED`, `CANCELLED`, and `REMOVED`. Terminal records are retained privately for safe retries and reused on a new request, rather than physically deleted. Public friend-list browsing is not allowed.

Notifications are at `users/{recipientUid}/event_notifications/friend_{senderUid}`. A request writes both friendship documents and its notification atomically. Resolving it updates both documents and deletes the notification. Friend requests do not depend on the event after sending.

Lists load in bounded pages of 20 with realtime listeners. Use Refresh to reload pagination after substantial list changes. Spark quotas still apply; no billing-dependent backend has been added. All UI strings support English and Bahasa Indonesia.

## Verification boundary

Source review, Dart formatting, and localization generation only. No tests, analyzer, builds, device runs, Firebase deployment, or live database mutations were performed.
