# Project Guidelines

## Code Style
- Follow existing Dart/Flutter style in lib/: small focused files and clear module boundaries.
- Keep UI widgets mostly presentational; put data loading and coordination in Riverpod providers.
- Use existing error/result patterns in lib/core/errors and avoid ad-hoc exception strings in UI.
- Keep localization keys in lib/core/i18n/locale_keys.dart and translation values in assets/i18n/*.json.

## Architecture
- App bootstrap and global setup live in lib/app/.
- Shared cross-cutting infrastructure lives in lib/core/.
- Feature code lives in lib/features/<feature>/ with clear separation across domain, data, providers, and ui.
- Preserve cache + network fallback behavior in weather flows (stale data is a valid fallback state).

## Build and Test
Use these commands unless task context requires otherwise:

```bash
flutter pub get
flutter analyze
flutter test
flutter test -d windows integration_test -- --timeout=45m
flutter run --dart-define=OPENWEATHER_API_KEY=YOUR_KEY
```

Release/build references:
- Windows: flutter build windows --release
- Android: flutter build apk / flutter build appbundle
- iOS: flutter build ipa

## Conventions
- Runtime configuration comes from --dart-define values (see docs/configuration.md).
- Do not log API keys or precise user location; keep diagnostics sanitized.
- For Windows-focused fixes, prefer the smoke/testing docs before changing behavior.
- Do not duplicate large docs in responses; link to existing docs instead.

## Reference Docs
- docs/architecture.md
- docs/configuration.md
- docs/design-system.md
- docs/performance-metrics.md
- docs/testing-windows.md
- docs/windows-smoke-checklist.md
- docs/release.md
- docs/monitoring.md
- docs/accessibility-report.md
