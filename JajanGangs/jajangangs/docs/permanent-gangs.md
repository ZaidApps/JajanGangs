# Permanent gangs — setup and behavior

## Publish before using

1. Replace and publish the full root `firestore.rules` in Firebase Console → Firestore → Rules.
2. Add the composite index declared in `firestore.indexes.json`: collection `gangs`, query scope **Collection**, `memberIds` **Arrays**, `createdAt` **Descending**. Wait for Enabled.
3. Keep the existing collection-group `event_notifications` index (`recipientIds` Arrays, `createdAt` Descending). It also serves permanent gang invitations and messages.

No Cloud Functions, Firebase Storage, automatic OS push, or Blaze requirement is introduced.

## Flow

Chats contains Jajan chats and My Gangs. Create Gang is available from the toolbar and My Gangs. Choose a name (1–40 characters), a bundled character avatar, and a capacity of 2–12 including the owner (default 2).

All members can invite their own accepted friends. Both directions of blocking are checked. One pending invitation per recipient and gang is allowed; duplicate sends do not create another notification. Invitation acceptance rechecks friendship, inviter membership, gang state and capacity in a transaction. Pending invites do not reserve places. A full gang gives a clear error and leaves the invitation pending. Recipients accept/reject from the existing notifications page; acceptance opens the chat.

Permanent chat messages appear optimistically and show pending/sent/failed status, with retry using the same message ID. Messages are paginated (50 at a time); gang lists use 20-document pages. The member list displays bundled avatars. Unread cursors and hidden-chat preferences are private per member; swiping hides until the latest message ID changes. Messages also use the existing latest-10 in-app notification feed and sound setting.

Owners can rename, adjust capacity (never below current membership), remove members, transfer ownership to an existing member, or delete the gang. Other members can leave. Owners transfer before leaving. Removed members immediately lose server access to messages; the active view clears its message data. Membership names/avatars are snapshots, as in event member records.

## Schema and deletion

`gangs/{id}` holds metadata, owner, bounded member ID list/map, and latest-message reference (no message text). Subcollections: `messages`, `chat_state`, `event_notifications`. Rules enforce profile-backed member identity, friend-only invitations, atomic acceptance, member-only posting, owner management, and self-only cursors. Pending invitees can inspect gang metadata, but message text is kept in member-only message documents. Invitation documents use recipient UID IDs; the message notification uses `message`.

Deletion first freezes the gang as DELETING, then deletes child documents in batches of at most 100, then deletes the parent. If the app closes or connectivity fails, the owner can reopen the gang and choose Finish deleting gang. A client-driven Spark implementation cannot continue cleanup while the app is closed. This avoids orphaned data in the normal deletion flow and makes partial cleanup recoverable.

Source reviewed, Dart formatted, and localization generated. Per user instruction, no tests, analyzer, builds, rules emulator, or device runs were performed. Rules and indexes have not been deployed by this task.
