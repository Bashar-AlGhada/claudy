import 'package:claudy/features/weather/domain/models/geo_coordinate.dart';

class Place {
  const Place({
    required this.name,
    required this.country,
    required this.coordinate,
  });

  final String name;
  final String country;
  final GeoCoordinate coordinate;
}

