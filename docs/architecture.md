# Architecture

## Stack

- State management: Riverpod
- Navigation: go_router
- Networking: Dio
- Localization: GetX + `LocaleKeys` + JSON assets
- Caching: Hive (JSON snapshots, schema versioned)

## Module Boundaries

- `core/`
  - Cross-cutting concerns: configuration, routing, time, errors/results, i18n, location, notifications, background scheduling.
- `features/weather/`
  - `domain/`: entities and repository interface
  - `data/`: provider adapters, repository implementation, cache implementation
  - `ui/`: screens and widgets
- `features/search/`
  - OpenWeather geocoding search + UI to set manual coordinate
- `features/map/`
  - Swappable map provider interface with a baseline canvas implementation
- `features/settings/`
  - Theme, language, location mode, background refresh, and notifications controls

## Data Flow

- UI reads location from `locationProvider`
- UI reads weather from `weatherReadingProvider`
- `weatherReadingProvider` calls `WeatherRepository.getWeather`
- Repository:
  - Returns fresh cache when available
  - Otherwise fetches network via `WeatherProvider`
  - Writes snapshot to cache
  - On network failure, returns stale cached snapshot when possible

