# UI localization requirement

All new or changed app-owned user-facing text must support English and Bahasa Indonesia. English is the default.

- Add matching entries to `l10n/app_en.arb` and `l10n/app_id.arb` and run `flutter gen-l10n` after changes.
- Use generated `context.l10n` accessors; never hard-code user-facing sentences in widgets.
- Include validation, error/loading states, accessibility labels, tooltips, dialogs and notifications.
- Controllers/services emit stable localization keys; resolve them in the view via `LocalizedMessages.message`. Update that mapping when adding message keys.
- Use typed ARB placeholders/plurals instead of string concatenation. Do not translate personal names, email addresses, user-generated content or branding.
- Preserve the saved locale and current form/session state when switching language.
- See `../docs/localization.md` for the workflow. Never edit generated localization Dart manually.
- Read and write localization/source files explicitly as UTF-8. Preserve punctuation and emoji; do not round-trip UTF-8 text through Windows legacy encodings.
