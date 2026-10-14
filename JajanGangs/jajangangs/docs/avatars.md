# Character avatars

Ten original Canvas-drawn characters are defined in `lib/widgets/character_avatar.dart`: cat, frog, robot, panda, fox, bunny, bear, alien, penguin, and monster. They are bundled as code and require no asset downloads, Firebase Storage, or external image service. Localized names and accessible selection states accompany the grid. No character is preselected; the user must choose one.

Email registration collects name, avatar, email and password. The avatar draft is saved privately on-device under the new Firebase UID while email verification is pending. After verification, name and avatar are saved together in `users/{uid}`. If the draft is unavailable (for example on another device), setup asks for the choice again. Only the stable `avatarId` is stored in Firestore.

New Google users choose a name and avatar before entering the map. Existing name-only profiles retain their name and are sent to setup to choose an avatar. Profiles with an unrecognized/missing avatar are treated as incomplete. Existing complete profiles skip setup. The Home Map profile control and profile panel render the saved character.

## Required Firebase step

Publish the updated root `firestore.rules` in Firebase Console > Firestore Database > Rules before using this version. The previously deployed name-only schema rejects the new `avatarId` field. The updated rules keep verified-user ownership checks, require one of the ten allowed IDs, and preserve `createdAt` on updates. Existing name-only records can still be read and upgraded; no bulk migration is required. Older app versions that write name-only profiles need to be updated.

No rules were deployed automatically. No tests, builds or device runs were performed, as requested. Localization generation and formatting were performed.
