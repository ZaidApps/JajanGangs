# Character avatars

Ten original anime portraits are bundled in `assets/avatars/anime_01.webp` through `anime_10.webp`. They replace the previous Canvas characters wherever `CharacterAvatar` is used: registration, profiles, chat and member cards. Each image is 512 x 512 WebP; the complete set is 368,616 bytes. Widgets decode at a shared 256 x 256 size and use Flutter's image cache. No Firebase Storage, image downloads or additional Firestore reads are needed.

The approved teal-jacket character (`anime_01`) is the default for legacy, missing or unknown avatar IDs. Historical IDs remain valid for existing profiles and security-rule comparisons; display fallback does not rewrite stored data. Existing complete profiles skip onboarding. Users can choose a new character in Edit Profile and save it with their name and bio. Historical member/message snapshots retain their saved avatar ID; they are not bulk-updated when a user edits their profile.

Email registration collects name, avatar, email and password. The avatar draft is saved privately on-device under the Firebase UID while email verification is pending. After verification, name and avatar are saved together in `users/{uid}`. If the draft is unavailable, setup asks for the choice again. New Google users choose a name and avatar before entering the map. No avatar is preselected for new registration. Only the stable `avatarId` is stored in Firestore.

The picker has English and Bahasa Indonesia names, accessible selection states and a checkmark. Permanent-gang creation uses the same catalog.

Tapping a choice opens a large animated preview before confirming it. Motion assets, per-character movement, lifecycle handling and active-event host portrait synchronization are described in `animated-avatars.md`.

## Required Firebase step

Publish the complete root `firestore.rules` in Firebase Console > Firestore Database > Rules before using new avatar choices. Both user-profile and permanent-gang allowlists accept `anime_01` through `anime_10`, alongside the old IDs. No new index or migration is required. A new app build is needed to bundle the assets.

No rules were deployed automatically. Formatting, localization generation, source review and artwork inspection were performed. No tests, analyzer, build or device run was performed, as requested.

## Artwork provenance

Generated using the built-in `image_gen` tool, using the approved sample as the style reference for the other nine portraits. Source-output paths are recorded in `avatar-art-sources.json`. Final app assets are the WebP files in `assets/avatars/`; originals are not runtime dependencies. Prompts and character descriptions are in `avatar-art-prompts.md`.
