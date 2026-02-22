import 'package:claudy/features/weather/domain/models/weather_snapshot.dart';

enum WeatherDataSource { network, cache }

class WeatherReading {
  const WeatherReading({
    required this.snapshot,
    required this.isStale,
    required this.source,
  });

  final WeatherSnapshot snapshot;
  final bool isStale;
  final WeatherDataSource source;
}

