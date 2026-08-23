import 'package:claudy/core/http/dio_client.dart';
import 'package:claudy/core/location/reverse_geocoder.dart';
import 'package:claudy/core/logging/app_logger.dart';
import 'package:claudy/features/weather/domain/models/geo_coordinate.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final reverseGeocoderProvider = Provider<ReverseGeocoder>(
  (ref) => BigDataCloudReverseGeocoder(dio: ref.watch(dioProvider)),
);

/// Reverse geocoding via BigDataCloud's free client endpoint (no API key).
class BigDataCloudReverseGeocoder implements ReverseGeocoder {
  BigDataCloudReverseGeocoder({required Dio dio}) : _dio = dio;

  static const _endpoint =
      'https://api.bigdatacloud.net/data/reverse-geocode-client';

  final Dio _dio;

  @override
  Future<String?> resolveName(GeoCoordinate coordinate, {String? languageCode}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        _endpoint,
        queryParameters: {
          'latitude': coordinate.lat,
          'longitude': coordinate.lon,
          'localityLanguageCode': languageCode ?? 'en',
        },
        options: Options(
          receiveTimeout: const Duration(seconds: 4),
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      final status = response.statusCode ?? 0;
      if (status >= 400) {
        AppLogger.warn('Reverse geocoding failed with HTTP $status');
        return null;
      }
      return parseName(response.data);
    } catch (e, s) {
      AppLogger.warn(
        'Reverse geocoding failed for ${coordinate.lat},${coordinate.lon}',
        error: e,
        stackTrace: s,
      );
      return null;
    }
  }

  /// Extracts "City, Country" from a BigDataCloud reverse-geocode payload,
  /// preferring [city], then [locality]. Returns null without either.
  static String? parseName(Map<String, dynamic>? data) {
    if (data == null) return null;
    final primary = _nonEmpty(data['city']) ?? _nonEmpty(data['locality']);
    if (primary == null) return null;
    final country = _nonEmpty(data['countryName']);
    return country == null ? primary : '$primary, $country';
  }

  static String? _nonEmpty(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
