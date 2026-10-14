# Phases 9–10: event progress and polish

- The host can advance an active event from `DESTINATION_SELECTED` to `ON_THE_WAY`, then `COMPLETED`, through event details or chat. Firestore transactions and rules enforce ownership and sequence. The existing 45-minute expiry is unchanged; transitions must happen before expiry.
- Members see the localized Going There label in chat and event details. A completion arriving while chat is visible opens the celebration screen. Completed chats also provide a celebration button, so reopening chat history does not force the screen again.
- The completion screen lists the host and accepted members, with loading/retry handling. Done returns to the root/home route. Existing chat history remains readable; sending and voting stop on completion. A completed event no longer blocks creating another Jajan, even if its ID remains in the reusable active-slot document.
- Creation now accepts an optional 150-character description, persisted with the retry draft and shown in event details. Existing events/drafts without a description use an empty value. The client and Firestore rules validate its length.
- Before a poll exists, chat shows only a compact Create Vote button to the host. Instructions remain in the creation dialog. Active polls and results keep their cards.
- Bubbles now shrink to content with smaller padding and a compact localized time; longer messages wrap within a maximum width.
- Corrupted punctuation in both ARB files was repaired, then localization Dart files were regenerated from UTF-8 sources. User-authored names, descriptions and messages are not translated or rewritten.

## Firebase setup

Publish the complete updated root `firestore.rules` in Firebase Console → Firestore Database → Rules. **No new indexes are required.** Spark remains supported; no Cloud Functions, OS push, migrations, or billing changes are introduced.

Source review, formatting and localization generation only. No tests, analyzer, builds, device runs or Firebase deployments were performed.
