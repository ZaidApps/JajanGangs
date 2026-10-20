# Profile and card actions

Publish the full root firestore.rules to permit the optional bio on user profiles. Existing profiles without bio remain valid. No new index or paid backend is required.

Email registration retains the optional bio in a UID-scoped local draft until verification; Google onboarding saves it with the profile. Edit Profile updates name and bio using the existing authenticated profile transaction. Bio is limited to 150 characters and shown beneath the name on the owner's profile, not in chat, event or member cards. Existing historical messages and member snapshots retain their original names.

Swipe a chat toward the leading edge (left in English/Indonesian) to use the same confirmed, per-user hide action as its menu. New messages bring it back. Food memory cards have owner-only edit/delete menus; deletion requires confirmation and reports failures.

All added labels support English and Indonesian. No tests, analyzer, builds or device runs were performed, as requested.
