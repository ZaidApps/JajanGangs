# Public and Private Jajan events

New event forms default to Public. Private requires host approval. Both types remain discoverable on the nearby map; Private does not mean hidden or invite-only.

The new `joinPolicy` field is `public` or `private`. The existing `visibility: public` continues to mean discoverable. Missing `joinPolicy` defaults to `private`, preserving approval-based joining for existing events and old saved drafts without a migration. The policy is chosen at creation and cannot be changed by later client updates.

Public joining atomically appends the authenticated user to `memberIds`, increases `memberCount`, and creates their accepted member snapshot in `join_requests/{uid}`. This uses the existing member-list, chat, inbox, and friends paths without a pending request. An atomic member_joined notification informs the host by name; tapping it opens event details. Repeated joins reuse the same user document. Transactions retry conflicting updates, and rules require space, an active OPEN event, the caller's own profile, and the coupled membership write. Full, expired, completed, and cancelling events cannot be joined.

Private joining retains the request, host notification, acceptance/rejection, and decision notification flow. Public event details omit host request controls and show immediate-join wording. Both languages include the new labels and explanations.

## Deployment

Publish the complete updated root `firestore.rules` before using the new version. No new Firestore index is needed: nearby discovery still uses the existing visibility and area query. Firebase Spark remains supported.

Source reviewed, localization generated, and changed Dart files formatted. No tests, analyzer, builds, device runs, or deployment performed, per the project instructions.

Any accepted member can create the single destination poll while the event is OPEN. Only the host can close the poll and select the final destination. Publish the updated rules; no additional index is needed.
