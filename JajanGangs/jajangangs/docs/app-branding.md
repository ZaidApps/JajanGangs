# App icon and splash branding

Artwork generated with the built-in image-generation tool. Source assets live in `assets/branding/`.

Concept/prompt: a smiling golden dumpling in a teal noodle bowl shaped like a location pin, chunky chopsticks, navy outlines, a polished cartoon game aesthetic, gold/teal palette, no text or watermark. The second generation removes the navy backdrop while preserving the mascot for transparent splash/adaptive-icon use.

- `app_icon_source.png`: opaque master icon.
- `mascot.png`: transparent mascot for splash screens and adaptive launchers.
- `tool/generate_brand_assets.ps1`: reproducible platform resizing/packaging using System.Drawing. Run from PowerShell to regenerate PNG sizes after replacing the masters.
- Android: legacy density-specific icons, adaptive icon foreground with mask-safe padding, navy launch background, and Android 12+ splash theme for light/dark modes.
- iOS: all existing iPhone/iPad/App Store icon sizes regenerated as opaque RGB; centered 240pt mascot in the native launch storyboard.
- Flutter: short mascot/wordmark transition with localized existing tagline, reduced-motion support, and immediate underlying app initialization.

No added packages or backend changes. Native resources require a fresh app installation/build to appear; hot reload cannot change launcher icons or native launch screens. Launcher/OS caches may retain old artwork temporarily.

Artwork inspected and Dart formatted. No tests, analyzer, builds, or device runs performed per project instructions. Android/iOS runtime appearance has not been verified on devices.

## Wordmark revision

Built-in image generation edited the icon with this prompt: preserve the golden dumpling, teal noodle bowl/pin and chopsticks; add exact stacked text JAJAN / GANGS across the lower bowl in large playful arcade lettering, gold/orange JAJAN, cream GANGS, navy outline and teal rim; keep the face visible and retain navy launcher-safe margins. A second edit removed only the outer navy backdrop to produce the matching transparent splash/adaptive foreground.

Both source files now include the wordmark. All platform PNG variants were regenerated. Flutter uses the illustrated title instead of a duplicate plain-text heading; the localized tagline remains. The icon's smallest system sizes necessarily show less lettering detail than the splash artwork.
