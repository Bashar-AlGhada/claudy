# Claudy

A Flutter weather app built with Riverpod, go_router, and GetX translations.

## Quick Start

Prerequisites:

- Flutter SDK 3.11+
- A valid OpenWeather API key

Commands:

```bash
flutter pub get
flutter run --dart-define=OPENWEATHER_API_KEY=YOUR_KEY
```

## Configuration

Runtime flags:

- --dart-define=WEATHER_PROVIDER=openweather
- --dart-define=OPENWEATHER_API_KEY=YOUR_KEY

## Docs

- [Architecture](docs/architecture.md)
- [Configuration](docs/configuration.md)
- [Design System](docs/design-system.md)
- [Performance Metrics](docs/performance-metrics.md)
- [Testing on Windows](docs/testing-windows.md)
- [Release](docs/release.md)
- [Monitoring](docs/monitoring.md)
- [Bug Report Template](docs/bug-report-template.md)

## Project Notes

- User-facing app code is under lib/
- Automated tests are under test/ and integration_test/
- Platform folders (android/, ios/, windows/, etc.) contain runner/build configuration

