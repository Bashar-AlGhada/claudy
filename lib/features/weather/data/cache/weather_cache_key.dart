import 'package:claudy/features/weather/domain/models/geo_coordinate.dart';

String weatherCacheKey({
  required String providerName,
  required GeoCoordinate coordinate,
}) {
  final lat = (coordinate.lat * 10000).round() / 10000;
  final lon = (coordinate.lon * 10000).round() / 10000;
  return 'weather:$providerName:$lat,$lon';
}

