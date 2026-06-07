# App Icon

Put your mosque logo here:

- `app_icon.png`            — full square logo, 1024×1024 px (used for iOS + Android legacy icon)
- `app_icon_foreground.png` — logo only (transparent background), 1024×1024 px,
                              with the mosque centered in the middle ~66% (safe zone),
                              used for the Android 8+ adaptive icon on the navy background.

If you only have one file, copy it to BOTH names — it will still work,
just make sure the mosque has some padding around it so the adaptive
icon doesn't get cropped.

Then run from the project root:

    flutter pub get
    dart run flutter_launcher_icons

This regenerates every Android mipmap-* and iOS AppIcon.appiconset size.
Rebuild the app afterwards:  flutter build apk --release
