import 'dart:async';

import 'package:claudy/core/location/location_provider.dart';
import 'package:claudy/core/logging/app_logger.dart';
import 'package:claudy/core/time/clock_provider.dart';
import 'package:claudy/features/weather/data/cache/weather_cache_key.dart';
import 'package:claudy/features/weather/data/cache/weather_cache_policy.dart';
import 'package:claudy/features/weather/data/cache/weather_cache_provider.dart';
import 'package:claudy/features/weather/data/weather_provider_selector.dart';
import 'package:claudy/features/weather/data/weather_repository_impl.dart';
import 'package:claudy/features/weather/domain/models/geo_coordinate.dart';
import 'package:claudy/features/weather/domain/models/weather_reading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final weatherReadingProvider = AsyncNotifierProvider<WeatherReadingNotifier, WeatherReading?>(
  WeatherReadingNotifier.new,
);

class WeatherReadingNotifier extends AsyncNotifier<WeatherReading?> {
  static const _hours = 24;
  static const _days = 7;

  @override
  Future<WeatherReading?> build() async {
    final location = await ref.watch(locationProvider.future);
    final coordinate = location.coordinate;
    if (coordinate == null) return null;

    final provider = ref.watch(activeWeatherProvider);
    final cache = await ref.read(weatherCacheProvider.future);
    final key = weatherCacheKey(
      providerName: provider.attributionName,
      coordinate: coordinate,
    );
    final now = ref.read(clockProvider).now();

    final cached = await cache.read(key);
    if (cached == null) {
      final result =
          await ref.read(weatherRepositoryProvider).getWeather(coordinate, hours: _hours, days: _days);
      return result.fold((failure) => throw failure, (reading) => reading);
    }

    final isStale = now.difference(cached.fetchedAt) > weatherSnapshotTtl;
    if (isStale) {
      unawaited(_revalidate(coordinate));
    }
    return WeatherReading(
      snapshot: cached,
      isStale: isStale,
      source: WeatherDataSource.cache,
    );
  }

  Future<void> refresh({bool forceRefresh = true}) async {
    final location = await ref.read(locationProvider.future);
    final coordinate = location.coordinate;
    if (coordinate == null) {
      state = const AsyncData(null);
      return;
    }

    state = await _fetch(coordinate, forceRefresh: forceRefresh);
  }

  Future<AsyncValue<WeatherReading?>> _fetch(
    GeoCoordinate coordinate, {
    bool forceRefresh = false,
  }) {
    final repo = ref.read(weatherRepositoryProvider);
    return repo
        .getWeather(coordinate, hours: _hours, days: _days, forceRefresh: forceRefresh)
        .then(
          (result) => result.fold(
            (failure) => AsyncError(failure, StackTrace.current),
            AsyncData.new,
          ),
        );
  }

  Future<void> _revalidate(GeoCoordinate coordinate) async {
    final next = await _fetch(coordinate, forceRefresh: true);
    if (!ref.mounted) return;
    if (next is AsyncError<WeatherReading?>) {
      AppLogger.warn(
        'Weather revalidation failed; keeping cached data',
        error: next.error,
        stackTrace: next.stackTrace,
      );
      return;
    }
    state = next;
  }
}
