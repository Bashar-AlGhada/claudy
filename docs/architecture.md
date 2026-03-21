# Architecture

## Stack used in this repo

- State: Riverpod
- Navigation: go_router
- HTTP: Dio
- Localization: GetX translations with static LocaleKeys
- Cache: Hive-backed weather snapshot storage

## Folder responsibilities

- core/: shared infrastructure (errors, logging, time, i18n, diagnostics, notifications)
- features/weather/: weather domain models, provider adapters, cache/repository logic, weather UI
- features/search/: place search and manual location flow
- features/map/: map UI and map-provider abstraction points
- features/settings/: language, theme, diagnostics export, and feature toggles

## Weather read path

1. UI asks weatherReadingProvider for the selected coordinate.
2. Provider calls WeatherRepository.
3. Repository checks cache freshness.
4. If cache is fresh, it returns immediately.
5. If cache is stale or missing, it fetches network data, writes cache, and returns fresh data.
6. If network fails and cache exists, stale data is returned with stale state.

## Notes

- Keep provider adapters isolated from UI and domain models.
- Keep fallback behavior deterministic and covered by tests.

