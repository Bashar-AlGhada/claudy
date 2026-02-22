# Configuration

## Weather Provider

Weather providers are selected via `--dart-define`.

- `WEATHER_PROVIDER`
  - Default: `openweather`
  - Used by `activeWeatherProvider`

## OpenWeather API Key

- `OPENWEATHER_API_KEY`
  - Required for weather and geocoding search

Example:

`flutter run --dart-define=OPENWEATHER_API_KEY=YOUR_KEY`

## Localization

- Assets are loaded from `assets/i18n/*.json`.
- All UI strings are referenced through `LocaleKeys`.

