# Release

## Android

- Confirm required permissions in android/app/src/main/AndroidManifest.xml.
- Build artifacts:

```bash
flutter build apk
flutter build appbundle
```

## iOS

- Confirm usage descriptions in ios/Runner/Info.plist.
- Build artifact:

```bash
flutter build ipa
```

## Release Checklist

- Keep OPENWEATHER_API_KEY out of source control.
- Prefer CI-managed secrets per environment.
- Verify diagnostics export does not include sensitive values.

