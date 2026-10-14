# Phase 6 — Temporary gang chat

The event is the temporary gang. Its owner and accepted members can open the chat from event details or the Home Chats inbox. Pending and rejected applicants cannot read messages. Public event details expose only the owner and accepted-member snapshots, not private profiles.

The game-inspired navy/gold chat includes character avatars, outlined bubbles, mint outgoing messages, timestamps, and a member panel. All interface text supports English and Bahasa Indonesia.

The latest 30 messages are streamed, with older messages fetched in pages of 30. Sending immediately inserts a local bubble; a clock indicates pending, a checkmark confirms storage, and red failure bubbles offer retry using the same message ID. Messages are limited to 1,000 characters. Sending requires a connection; local pending bubbles are not a persistent offline outbox.

Sending now writes a message, private shared summary, and grouped notification atomically through Firestore. No Cloud Functions are required. Members retain private read cursors. Expiry/completion closes sending while retaining history. Cancellation cleans up child collections before deleting the event; the owner's app must complete or resume cleanup.

Follow [Spark setup](spark-setup.md) for the rules and indexes to publish. OS push and automatic server-side cleanup are deferred while we stay on Spark. In-app notifications use Firestore listeners and show stored activity on reconnection.

See [chat enhancements](chat-enhancements.md) for inbox and notification behavior. No tests, analyzer, builds, device runs, or deployments were performed for the Spark conversion.
