# Authentication setup

The app supports email/password and Google sign-in. The updated native Firebase files supplied on September 29 are installed. Android now has Android and web OAuth clients. iOS has its client ID and callback URL scheme configured in Runner/Info.plist. Native Firebase configuration files alone do not enable Email/Password; that provider must also be enabled in the console. The steps below document the setup for future configuration changes.

## Firebase console (project jajangangs)

1. Open Authentication > Get started (if needed) > Sign-in method.
2. Enable **Email/Password** (the password option, not email-link sign-in) and save.
3. Enable **Google**, select a project support email, and save.
4. Open Project settings > Your apps > Android `com.zaidjoapps.jajangangs`.
5. Add this machine's debug signing fingerprints:

   SHA-1: `12:23:F3:9A:AE:CE:3B:5A:0A:2B:A2:83:47:FE:82:CE:9B:76:B8:92`

   SHA-256: `77:BD:91:72:9D:25:EF:8C:36:5F:6D:C5:02:38:05:FF:99:2B:74:6E:D7:A7:8B:15:60:9E:F8:9F:E8:73:5D:6A`

6. Download the updated `google-services.json` and replace `android/app/google-services.json`. It must contain a web OAuth client (`client_type: 3`); do not fabricate a client ID. The package name and registered signing certificate must also match this build. Release builds need their own signing fingerprint when release signing is configured.
7. Stop and rebuild the app with `flutter run`. Hot reload cannot update native Google configuration.

## Profile storage

Create the Cloud Firestore database, then publish the project's `firestore.rules` through the Rules tab. These rules grant verified users access only to their own name profile. They deny all other collections until those features are implemented. Review any existing deployed rules before replacing them.

Email registration creates the Auth account first and sends a verification link. After verification, the app saves the chosen name to `users/{uid}`. Google users confirm a name on their first login. A profile failure is retriable and does not require creating a second account.

## Diagnosing an email failure

If registration still fails after enabling Email/Password, use the updated app and copy the `[Auth] firebase_auth/...` debug-console line or the error code shown on screen. The app logs codes only, not passwords, tokens, emails, or raw exception messages. An `internal-error` is not enough by itself to conclude that a provider is disabled. Known configuration errors wrapped by Android are now identified separately.

## Other platforms

Web: register a Firebase web app; copy `config/auth.example.json` to ignored `config/auth.local.json`, fill the FIREBASE_WEB values from that app's config, and run `flutter run -d chrome --dart-define-from-file=config/auth.local.json`. Add the development hostname (including localhost if needed) to Authentication > Settings > Authorized domains.

iOS: the supplied `GoogleService-Info.plist` is installed, and Runner/Info.plist contains its CLIENT_ID as GIDClientID and REVERSED_CLIENT_ID as the callback URL scheme. No Google dart-define is required. When switching Firebase projects, update both plist files together. GOOGLE_IOS_CLIENT_ID remains an optional override, but the callback scheme must match it.

No tests or builds were run after installing the updated configuration, as requested.

References: [Firebase password authentication](https://firebase.google.com/docs/auth/flutter/password-auth), [Android Google sign-in setup](https://pub.dev/packages/google_sign_in_android), [iOS Google sign-in setup](https://pub.dev/packages/google_sign_in_ios).
