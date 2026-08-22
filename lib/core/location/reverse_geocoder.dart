import 'package:claudy/features/weather/domain/models/geo_coordinate.dart';

/// Resolves a human-readable place label for a coordinate.
abstract class ReverseGeocoder {
  /// Returns e.g. "Amsterdam, Netherlands", or null when nothing usable
  /// was resolved. Implementations must fail soft.
  Future<String?> resolveName(GeoCoordinate coordinate, {String? languageCode});
}
