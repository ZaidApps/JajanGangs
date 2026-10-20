# Animated character selection

The avatar picker now opens a large navy/gold character preview. Choose this character confirms the selection; closing/back/barrier dismissal preserves the existing choice. This shared picker is used by email registration, Google onboarding, Edit Profile and permanent-gang creation. All new text supports English and Bahasa Indonesia.

## Local motion assets

`assets/avatars/motion/anime_01.webp` through `anime_10.webp` are expression keyframes, not animated GIFs. Together they add 350,060 bytes (about 342 KiB). With the original portraits the full collection is about 702 KiB. Flutter blends the two images and applies small transforms inside the stationary badge. Only the currently opened preview has an animation controller; all small list/profile/chat avatars remain static.

The preview stops motion when covered, when the app is not resumed, or when reduced motion is enabled. Closing it disposes its controller. Image decode size is capped at 512 pixels and images use Flutter's asset cache. No network image loading, Firebase Storage, extra listeners or paid service is introduced.

| Character | Motion |
| --- | --- |
| Noodle Adventurer | Gentle tilt and blink (approved sample) |
| Sunny Foodie | Playful wink and leftward tilt |
| Cafe Explorer | Soft nod and blink |
| Midnight Gamer | Small tilt and double blink behind glasses |
| Street Food Scout | Wider tilt and wink |
| Spicy Sidekick | Light bob and confident wink |
| Weekend Wanderer | Slow tilt and relaxed blink |
| Sweet Treat Hunter | Gentle sway and double blink |
| Chill Challenger | Small nod, reverse tilt and longer wink |
| Golden Foodie | Calm nod and double blink |

Keyframes were created with built-in `image_gen`. Exact prompts and source paths are in `avatar-motion-sources.json`; the approved first sample is documented in `output/avatar-motion/README.md`. Only the eye regions were composited onto the original portraits to keep other artwork stable, then encoded as 512-pixel WebP. Final assets live in the workspace and do not depend on the generation-output directory. The expression contact sheet is `output/avatar-motion/expression-review.jpg`.

## Host portrait synchronization

When saving a different profile avatar, `FirebaseAuthGateway.saveProfile` reads the user's `active_jajan_slots/{uid}` and, if present, its event document inside the existing profile transaction. If the event belongs to the user, has an active state and has not expired, the same transaction updates its `creatorAvatarId` and `updatedAt`. All reads precede writes. This adds at most two direct document reads and one event write per avatar-change transaction attempt, with no query or listener. A rejected commit cannot leave half the change saved.

The home map updates its own cached host portrait after the successful edit returns, without fetching events again. Event details already listen to the event document. Other users' map cards receive the new portrait on their normal event refresh. Historical messages/member snapshots and completed/cancelled events are not rewritten.

Firestore rules permit the verified host to change only `creatorAvatarId` and `updatedAt`, with the new avatar matching the post-transaction profile. Owner, participants, location, state and expiry remain protected. Rules restrict this operation to active event states, but avoid a deadline race if an event expires during the transaction. The client excludes expired events.

## Required setup

Publish the complete updated root `firestore.rules` before saving avatar changes while hosting an event. No new index, migration or Firebase billing plan is needed. Restart/rebuild the app to bundle the new motion assets.

Formatting, localization generation, source review and visual artwork inspection were performed. No tests, analyzer, builds or device runs were performed per project instructions. Runtime animation and Firestore commits still require verification on a device once requested.
