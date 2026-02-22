import 'package:claudy/core/location/location_provider.dart';
import 'package:claudy/features/weather/data/weather_repository_impl.dart';
import 'package:claudy/features/weather/domain/models/weather_reading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final weatherReadingProvider = FutureProvider.autoDispose<WeatherReading>((ref) async {
  final location = await ref.watch(locationProvider.future);
  final coordinate = location.coordinate;
  if (coordinate == null) {
    throw const _MissingCoordinateException();
  }
  final repo = ref.watch(weatherRepositoryProvider);
  final result = await repo.getWeather(coordinate, hours: 16, days: 5);
  return result.fold((failure) => throw failure, (reading) => reading);
});

class _MissingCoordinateException implements Exception {
  const _MissingCoordinateException();
}

