# Configuration

## Runtime Flags

Claudy reads provider settings through --dart-define values at launch.

- WEATHER_PROVIDER
  - Default: openweather
  - Current supported value in this repo: openweather

- OPENWEATHER_API_KEY
  - Required for weather reads and place search

## Example

```bash
flutter run \
  --dart-define=WEATHER_PROVIDER=openweather \
  --dart-define=OPENWEATHER_API_KEY=YOUR_KEY
```

## Localization

- Translation files are in assets/i18n/*.json.
- UI text is referenced through LocaleKeys.

## Security Notes

- Do not commit OPENWEATHER_API_KEY values to source control.
- Use environment-based secrets in CI pipelines.

