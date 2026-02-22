# Release

## Android

- Ensure required permissions exist in `android/app/src/main/AndroidManifest.xml`.
- Build:
  - `flutter build apk`
  - `flutter build appbundle`

## iOS

- Ensure usage descriptions exist in `ios/Runner/Info.plist`.
- Build:
  - `flutter build ipa`

## Notes

- Keep `OPENWEATHER_API_KEY` out of source control.
- Prefer CI secrets / per-environment configuration.

