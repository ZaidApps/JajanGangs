# Jajan Gangs

Mobile-first social food discovery app for Indonesia. Foundation targets Android and iOS.

Development currently targets **Firebase Spark**. Follow [Spark setup](docs/spark-setup.md) for the current rules and notification index. Chat and in-app activity use Firestore transactions; Cloud Functions and OS push delivery are deferred.

## Run locally

1. Install Flutter (current project: Flutter 3.47.5 / Dart 3.13.4), Android SDK and a device/emulator. Run `flutter doctor` and resolve Android toolchain issues.
2. On Windows, enable Developer Mode if Flutter reports missing symlink support.
3. Restore the Firebase client configuration files from project settings:
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`
   Both must use application ID `com.zaidjoapps.jajangangs`. The supplied files point to Firebase project `jajangangs`.
4. Copy `config/local.example.json` to `config/local.json` and set `MAPBOX_ACCESS_TOKEN` to a public `pk.` token. The local configuration is already populated on the current workstation.
5. Run:

```sh
flutter pub get
flutter run --dart-define-from-file=config/local.json
```

VS Code includes a launch configuration using this file. Do a full restart after changing build configuration.

```sh
flutter analyze --no-pub
flutter test --no-pub
flutter build apk --debug --dart-define-from-file=config/local.json
```

iOS builds require macOS/Xcode and signing setup. The Firebase plist is included in Runner resources; the project retains Flutter's Swift Package Manager integration. iOS builds have not been verified from Windows.

## MVC structure

- `lib/models`: data and immutable state, independent of views.
- `lib/views`: screens and presentation lifecycle.
- `lib/controllers`: state transitions and orchestration, using Flutter ChangeNotifier.
- `lib/services`: Firebase/Mapbox integration; future database and search access belongs here.
- `lib/config`: validated compile-time configuration.
- `lib/theme`: shared theme and spacing.
- `lib/widgets`: reusable buttons, text inputs, loading and error feedback.
- `lib/app.dart`: application composition; `lib/main.dart`: entry point.

The startup controller uses an injectable initializer for tests. The startup view owns and disposes the controller. Successful Firebase initialization and Mapbox token setup open the map; failures offer retry. The map separately handles loading and load errors.

## Configuration and scope

`--dart-define-from-file` supplies build-time values, not encrypted secrets. Public Mapbox tokens and Firebase client settings are recoverable from a compiled app. Never include secret Mapbox tokens, service-account credentials or signing keys. Local configuration and supplied Firebase files are ignored by Git.

There is one Firebase environment for now. Creating staging/production separation will require separate Firebase projects and native build flavors; changing the Mapbox token does not switch Firebase projects.

Only Firebase Core and the stable Mapbox Maps SDK are added for this phase. Firebase reads, writes, authentication, chat, push notifications and place search are not implemented yet. Firebase initialization verifies local SDK configuration; it does not prove backend service access or security rules.

The initial map shows a fixed Jakarta center, preserves Mapbox attribution controls, and never requests device location. Map movement performs no place searches. Custom game styling and event markers belong to the later map feature. Release signing is still the Flutter debug placeholder and must be configured before distribution.

## Foundation verification

Android runtime verification requires checking that the map tiles render, panning/zooming work, and retry recovers after a connection failure. Confirm Firebase initializes before the map opens. No mobile SDK/device was detected during initial setup, so build and live connectivity verification remain pending until the Android toolchain is available.

SDK references: [Mapbox setup](https://docs.mapbox.com/flutter/maps/guides/install/) and [Firebase Android configuration](https://firebase.google.com/docs/android/setup).

## Chrome preview

```sh
flutter run -d chrome --dart-define-from-file=config/local.json
```

Chrome displays a labeled visual preview of the app shell. It intentionally bypasses native startup: the selected stable Mapbox Flutter SDK and supplied Firebase config files target Android/iOS. The browser preview is not evidence of Firebase or Mapbox connectivity. Full web support would require a compatible web map integration and a registered Firebase web app.

Latest checks: `flutter analyze --no-pub` passed with no issues; all three startup tests passed. The Chrome debug preview launched successfully. Android APK build stopped because no Android SDK is installed/configured; iOS build and native Firebase/Mapbox runtime verification remain pending.

## Welcome page (Phase 1, Page 1)

The app now opens the shared WelcomeView. Mobile still initializes its native services first; Chrome renders the same welcome UI without Firebase/Mapbox initialization. The former map screen remains available for future navigation integration.

The shared gaming visual direction uses cream, lime, coral and lavender, dark outlines, tactile buttons, and original vector food artwork. The welcome layout stacks on phones and splits into two columns on wide screens. Its entrance animation respects reduced-motion settings. Get Started and Log In currently show brief coming-soon feedback; account creation and login routing are intentionally deferred to their respective pages.

Android compatibility: this project uses Flutter 3.47+ and AGP 9.1 with `android.builtInKotlin=true`. Mapbox 2.31.1 expects AGP 9's built-in Kotlin extension. Disabling it causes `Could not find method kotlin()` while evaluating the Mapbox plugin. Keep `android.newDsl=false` for Flutter's DSL compatibility. No package-cache edits are required.

Welcome verification: analysis passes; startup tests pass; the 320-pixel-wide, 200% text-scale test passes for layout and both placeholder button actions.

For Windows workspaces on a different drive from the Pub cache, Kotlin incremental compilation is disabled (`kotlin.incremental=false`) to avoid the compiler's `this and base files have different roots` cache failure. If the project and Pub cache later share a drive, this workaround can be reconsidered.

## Current welcome redesign

The app always opens WelcomeView directly on Android, iOS and web. No Mapbox token, Firebase initialization, network, or location permission is required to view it. The old StartupView/StartupService remain available for future feature entry points but are not invoked by main.dart. Authentication and map features must initialize the services they require when those features are implemented.

The full-screen city illustration is a bundled decorative asset, not a live map. Floating food markers are decorative and do not represent real events or a user's position. Branding and buttons remain Flutter widgets. The primary action reads "I'm Hungry! Let's Jajan!"; it and Log In show coming-soon feedback until the corresponding authentication pages are built. Motion respects the system's reduced-animation preference.

Launch the welcome screen normally with `flutter run`. For future map/service entry points, use `flutter run --dart-define-from-file=config/local.json`. A full restart is required after changing build-time configuration.

Artwork provenance and the exact generation prompt are recorded in assets/images/README.md.

Redesign validation: `flutter analyze --no-pub` reports no issues; all five tests pass. Browser preview visually checked with the bundled city background, food markers, branding, and primary/login controls. No Android installation was performed for this redesign; fully restart the currently running mobile app to load the new startup code and bundled image.

## Localization (current)

English is the default; English and Bahasa Indonesia are available from the EN/ID menu in the welcome screen's top-right corner and on authentication screens. The choice is saved on-device. All app-owned labels, validation, loading states and errors use shared Flutter ARB translations. See [the localization workflow](docs/localization.md) before adding UI text. Localization sources are `lib/l10n/app_en.arb` and `lib/l10n/app_id.arb`; run `flutter gen-l10n` after editing them.

Restart the app fully after this change because saved preferences add a native plugin. No tests or builds were run for this change, as requested.

## Home Map (current)

Completed profiles now enter the native Home Map after sign-in. This phase uses a bundled teal/gold Mapbox style, custom demo food pins, an approximate-location area, event preview cards, and Create Jajan / Profile / Gang controls. Event data is local only; Create Jajan and Gang are placeholders. Profile includes sign-out. English and Indonesian are supported.

Use `flutter run --dart-define-from-file=config/local.json` (or the existing VS Code local launch configuration). Fully restart for the added location plugin. See [Home Map details](docs/home-map.md) for privacy, fallbacks and scope. No tests, builds or device launches were run for this phase.

## Registration avatars

Email and first-time Google registration now require one of ten cartoon character avatars. Existing profiles without an avatar are prompted during their next profile load. Home shows the selected character. **Publish the updated `firestore.rules` before using this version**, because the previous rules reject `avatarId`. See [avatar setup and persistence](docs/avatars.md). No tests or app builds were run for this change.

## Create Jajan (current)

The Home **Create Jajan** action now opens a craving/capacity form and saves an OPEN event in Firestore using only an approximate area. Events have a 45-minute lifetime derived from their server creation timestamp. The creator's saved events appear alongside labeled demos; public discovery and joins are still deferred.

**Publish the updated `firestore.rules` and create the index in `firestore.indexes.json`.** See [Create Jajan setup and schema](docs/create-jajan.md). No tests, builds or real submissions were run.
