# Home Map (local demo phase)

After authentication and a saved name profile, AuthGate opens MapView. Returning users restore their session and profile before entering the map. Profile sign-out returns to Welcome.

## Launch

Fully restart the native app after adding the location plugin:

```sh
flutter run
```

The existing VS Code `Jajan Gangs (local)` launch configuration supplies this file. A valid public MAPBOX_ACCESS_TOKEN is required. Missing configuration produces an explanatory screen; web and desktop show the mobile-platform requirement instead of constructing a native map.

## Design and data

- `assets/maps/jajan_arcade.json`: teal water, green land, gold major roads, raised buildings and localized place labels where Mapbox supplies them.
- Four local sample events with original Canvas-rendered food-pin images. Selecting a pin or accessible event chip shows the corresponding preview card. The selected marker has a local pulse that respects reduced motion and app backgrounding.
- Sample events are generated around the selected approximate area. They are explicitly labeled as demos. Distances are rounded estimates from that area's center, not the user's exact position.
- Mapbox attribution and logo stay visible in the map viewport, outside the event panel.
- Create Jajan and Gang open placeholders. Profile opens a placeholder with the saved name and working sign-out.
- Every new Flutter string has English and Indonesian translations. The iOS permission reason is localized using the device's language settings.

## Location and privacy

Android requests coarse foreground location only. iOS requests when-in-use location with reduced accuracy by default. There is one request on entry; the user can explicitly update the area from the location-info panel. Recenter only moves the camera.

The location service rounds coordinates to a 0.02-degree grid before exposing them to the controller or map. Its original fix is neither stored nor logged nor sent to Firebase. An area polygon accounts for rounding and reported accuracy; no exact-location puck is enabled. Mapbox still fetches tiles for the approximate map viewport. No other users receive location data.

Denied permissions, disabled services, timeout, or unavailable location use a clearly labeled Jakarta preview. The location-info panel explains the reason and offers retry/settings. Map failure offers a refresh control; it never initiates place search.

## Scope and verification

No Firestore event reads/writes/listeners, join requests, place search, or live tracking are implemented. Existing authentication/profile reads remain unchanged. No tests, analyzer, app builds, or device launches were run for this phase, per the user's preference. Localization generation and Dart formatting are build preparation only.

The default public Mapbox token is bundled in `lib/config/app_config.dart` for Android and iOS. `config/local.json` and dart-define flags are optional overrides, not prerequisites. Copy updated sources to the Mac and rebuild iOS to include this default.
