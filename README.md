# Onestop · Snake Watch (demo)

A standalone demo of the **Snake Watch** add-on for IIT Guwahati's Onestop app: report snake sightings on a campus map, see nearby reports, and let the hostel authority mark areas safe.

- **Open it in your browser:** https://kaveiduo.github.io/snake-watch/
- **Android app (APK):** https://github.com/KaveiDuo/snake-watch/releases/latest/download/SnakeWatch.apk

This is a design demo built from the Figma prototype. It uses example data only: reports stay on your own device and reset when the app restarts, the snake scanner result is simulated, and there is no real sign-in.

## Build

```bash
flutter pub get
flutter build apk --release
flutter build web --release --base-href /snake-watch/app/
cp web/sw_cleanup.js build/web/flutter_service_worker.js && rm build/web/sw_cleanup.js
```

The web build doesn't use an offline service worker, so phones always load the latest version. The second web command replaces Flutter's worker with one that removes old caches.

On the original Windows PC use `build_apk.ps1`, which works around a Java temp-folder issue.

Snake photos: Wikimedia Commons. Map © OpenStreetMap contributors.
