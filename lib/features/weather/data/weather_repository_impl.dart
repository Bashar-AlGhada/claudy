import 'dart:math' as math;

import 'package:claudy/core/errors/app_failure.dart';
import 'package:claudy/core/errors/app_exception.dart';
import 'package:claudy/core/http/interceptors/rate_limit_interceptor.dart';
import 'package:claudy/core/result/app_result.dart';
import 'package:claudy/features/weather/data/cache/weather_cache.dart';
import 'package:claudy/features/weather/data/cache/weather_cache_key.dart';
import 'package:claudy/features/weather/data/cache/weather_cache_policy.dart';
import 'package:claudy/features/weather/data/cache/weather_cache_provider.dart';
import 'package:claudy/features/weather/data/weather_provider.dart';
import 'package:claudy/features/weather/data/weather_provider_selector.dart';
import 'package:claudy/features/weather/domain/models/geo_coordinate.dart';
import 'package:claudy/features/weather/domain/models/weather_reading.dart';
import 'package:claudy/features/weather/domain/models/weather_snapshot.dart';
import 'package:claudy/features/weather/domain/repositories/weather_repository.dart';
import 'package:claudy/core/time/clock_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final weatherRepositoryProvider = Provider<WeatherRepository>((ref) {
  final provider = ref.watch(activeWeatherProvider);
  return WeatherRepositoryImpl(ref: ref, provider: provider);
});

class WeatherRepositoryImpl implements WeatherRepository {
  WeatherRepositoryImpl({required Ref ref, required WeatherProvider provider})
      : _ref = ref,
        _provider = provider;

  final Ref _ref;
  final WeatherProvider _provider;

  @override
  Future<AppResult<WeatherReading>> getWeather(
    GeoCoordinate coordinate, {
    required int hours,
    required int days,
    bool forceRefresh = false,
  }) async {
    final cache = await _ref.read(weatherCacheProvider.future);
    final key = weatherCacheKey(providerName: _provider.attributionName, coordinate: coordinate);
    final now = _ref.read(clockProvider).now();

    final cached = await cache.read(key);
    final cachedAge = cached == null ? null : now.difference(cached.fetchedAt);
    final cachedIsStale = cachedAge == null ? true : cachedAge > weatherSnapshotTtl;

    if (!forceRefresh && cached != null && !cachedIsStale) {
      return Success(
        WeatherReading(
          snapshot: cached,
          isStale: false,
          source: WeatherDataSource.cache,
        ),
      );
    }

    try {
      final current = await _provider.getCurrent(coordinate);
      final hourly = await _provider.getHourly(
        coordinate,
        hours: math.max(0, hours),
      );
      final daily = await _provider.getDaily(
        coordinate,
        days: math.max(0, days),
      );

      final snapshot = WeatherSnapshot(
        coordinate: coordinate,
        providerName: _provider.attributionName,
        fetchedAt: now,
        current: current,
        hourly: hourly,
        daily: daily,
      );

      await cache.write(key, snapshot);

      return Success(
        WeatherReading(
          snapshot: snapshot,
          isStale: false,
          source: WeatherDataSource.network,
        ),
      );
    } catch (e) {
      final failure = _mapError(e);
      if (cached != null) {
        return Success(
          WeatherReading(
            snapshot: cached,
            isStale: true,
            source: WeatherDataSource.cache,
          ),
        );
      }
      return Failure(failure);
    }
  }

  AppFailure _mapError(Object e) {
    if (e is ConfigurationException) {
      return ValidationFailure(message: e.message);
    }
    if (e is RateLimitActiveException) {
      return RateLimitFailure(retryAfter: e.remaining);
    }
    if (e is DioException) {
      final status = e.response?.statusCode;
      if (status == 429) {
        return const RateLimitFailure(retryAfter: null);
      }
      return NetworkFailure(message: e.message ?? 'Network error');
    }
    return UnknownFailure(message: e.toString());
  }
}
