# Chat, member browsing, and in-app notifications

## Implemented behavior

- Sending inserts a bubble immediately and clears the input without waiting for Firestore. A clock means pending; one checkmark means Firebase confirmed the message (not a recipient read receipt). Failed attempts have a red background and a localized retry label. Retrying keeps the same document ID; a late acknowledgement replaces the local bubble rather than duplicating it. Multiple messages can be pending independently. Unconfirmed local bubbles are held for the current chat-screen session, not a persistent offline outbox.
- **View Members** on event details shows the owner and accepted members before joining. Verified users can read accepted request snapshots for public events, with names and avatars rendered. Private user profiles, pending/rejected requests, and chat contents remain restricted.
- The Home **Chats** button opens the inbox. It shows previews, timestamps, and green unread dots; older rooms load in pages of 20, independently of the notification limit. Visible rows watch their private state and room status. Existing rooms without a new summary get a one-message preview fallback. Room pagination uses creation order.
- Opening a chat marks the newest server-confirmed message as read while the route is visible and the app is in the foreground. Read cursors are monotonic and shared across devices. Backgrounded/covered chats do not silently clear unread state. A message racing with a read remains unread if newer than the cursor.
- The Home bell opens the latest **10 notification entries**. Acceptance/rejection are persisted notifications; new-message alerts are grouped per chat. The list has no older-notification pagination. Older stored entries are hidden, not bulk-deleted. All display text is English/Bahasa Indonesia; user messages/names are not translated.
- Cancellation now removes `join_requests`, `messages`, `chat_state`, `chat_summary`, and `event_notifications` before deleting the event. Update rules before using cancellation in this version.

## Firebase setup required

Follow [Spark setup](spark-setup.md) for the current rules and index configuration. The app writes previews and notifications in Firestore transactions; Cloud Functions are no longer required. OS push delivery is deferred. Do not deploy the previous notification functions.

The notification index now uses `recipientIds` **Array contains**, then `createdAt` **Descending**, with **Collection group** scope. Publish the complete root rules with the updated app.

No tests, analyzer, builds, device runs, or deployments were performed for the Spark conversion, as requested.
