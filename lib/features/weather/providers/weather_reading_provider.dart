import 'dart:async';

import 'package:claudy/core/location/location_provider.dart';
import 'package:claudy/core/time/clock_provider.dart';
import 'package:claudy/features/weather/data/cache/weather_cache_key.dart';
import 'package:claudy/features/weather/data/cache/weather_cache_policy.dart';
import 'package:claudy/features/weather/data/cache/weather_cache_provider.dart';
import 'package:claudy/features/weather/data/weather_provider_selector.dart';
import 'package:claudy/features/weather/data/weather_repository_impl.dart';
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
    if (cached != null) {
      final age = now.difference(cached.fetchedAt);
      final isStale = age > weatherSnapshotTtl;
      final reading = WeatherReading(
        snapshot: cached,
        isStale: isStale,
        source: WeatherDataSource.cache,
      );

      state = AsyncData(reading);
      if (isStale) {
        unawaited(refresh(forceRefresh: true));
      }
      return reading;
    }

    final repo = ref.read(weatherRepositoryProvider);
    final result = await repo.getWeather(
      coordinate,
      hours: _hours,
      days: _days,
    );
    return result.fold((failure) => throw failure, (reading) => reading);
  }

  Future<void> refresh({bool forceRefresh = true}) async {
    final location = await ref.read(locationProvider.future);
    final coordinate = location.coordinate;
    if (coordinate == null) {
      state = const AsyncData(null);
      return;
    }

    state = const AsyncLoading<WeatherReading?>();

    final repo = ref.read(weatherRepositoryProvider);
    final result = await repo.getWeather(
      coordinate,
      hours: _hours,
      days: _days,
      forceRefresh: forceRefresh,
    );

    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (reading) => AsyncData(reading),
    );
  }
}
