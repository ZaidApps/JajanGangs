# Personal chat visibility

Publish the full root `firestore.rules` before using Delete from my chats. No new index, Cloud Function, or billing plan is required.

The chat menu confirms hiding a conversation for the current user. A transaction merges `hiddenMessageId` and `hiddenAt` into `jajan_events/{eventId}/chat_state/{uid}` without changing the existing read cursor. Rules restrict these writes to the authenticated member and keep read cursor validation intact.

The inbox uses its existing chat state and summary listeners. A conversation stays hidden while its latest message ID matches the saved ID; a new message makes it visible again. Empty conversations use an empty ID. Shared messages, event membership, and other users' inboxes are untouched. The event details can still open a hidden conversation. A failed hide restores the card and displays a localized error.

All added text supports English and Indonesian. Source formatting and localization generation were performed; tests, analyzer, builds and device runs were not run, as requested.
