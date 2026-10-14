# Localization

English is the default. English (`en`) and Bahasa Indonesia (`id`) are supported throughout the Flutter UI. The welcome screen and authentication screens offer a language menu. The selected locale is stored on-device with SharedPreferencesAsync; changing it rebuilds localized text without replacing the authentication controller or clearing form input.

## Adding text

1. Add a descriptive key and translations to both `lib/l10n/app_en.arb` and `lib/l10n/app_id.arb`.
2. Use ICU placeholders for names, counts, and other variables. Declare placeholder types in the English ARB metadata. Do not concatenate translated fragments.
3. Run `flutter gen-l10n` (code generation, not a test). Generated Dart lives under `lib/l10n/generated`; never edit those files manually.
4. Import `l10n/l10n.dart` using the appropriate relative path and access `context.l10n.yourKey` in widgets.
5. Controllers and services return stable message keys, not translated sentences or BuildContext. Add new message keys to `LocalizedMessages.message` in `lib/l10n/l10n.dart`. The view resolves them when rendering so errors already on screen change with the locale.
6. Localize tooltips, semantics, placeholders, validation, loading/error states, dialogs and snackbars as well as visible labels. Flutter's built-in Material/Cupertino strings use the same locale.

Names, email addresses, user-generated text, and the Jajan Gangs brand are preserved. Native Google account chooser text follows Google/device settings. Browser Google sign-in receives a language hint. Verification/reset requests pass the selected language to Firebase; content still depends on Firebase email templates.

Existing map labels supplied by Mapbox are provider content, not Flutter UI translations. Future map styling and place data should account for language separately.

No tests or builds were run for this change, at the user's request.
