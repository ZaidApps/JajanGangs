# Foreground notification sound

A locally synthesized, 650ms two-note chime lives at `assets/audio/jajan_chime.wav` (mono PCM WAV, 44.1kHz). Soft attacks and a decaying tail avoid abrupt clicks. It requires no audio network service, Firebase change, or extra Flutter package.

Home → Profile → Notification sound controls the device-local preference. Default on; persistence failures leave the previous setting and show a localized message.

The existing newest-10 activity listener establishes a silent first server snapshot. Later new notification versions can play once, only in the foreground, when unread and newer than the latest foreground entry. Cached/pending snapshots, old notifications, read acknowledgements, and messages for the visible chat are silent. A three-second cooldown coalesces bursts. Reconnecting the listener starts a fresh silent baseline.

Android playback uses SoundPool with notification audio attributes and checks the ringer mode. iOS uses AVAudioPlayer with the ambient category to respect silent mode and mix with other audio. Audio errors never block notification delivery. Browser preview has no native audio implementation and stays silent.

Native changes require a new build/install; hot reload is insufficient. No OS background push sound or billing-dependent service was added. No rules or indexes need publishing.

Source reviewed, Dart formatted, and localization generated. No tests, analyzer, builds, device runs, or audio playback verification performed per project instructions.
