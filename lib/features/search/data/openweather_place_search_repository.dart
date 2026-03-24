import 'package:claudy/core/config/app_config.dart';
import 'package:claudy/core/errors/app_failure.dart';
import 'package:claudy/core/errors/app_exception.dart';
import 'package:claudy/core/http/dio_client.dart';
import 'package:claudy/core/result/app_result.dart';
import 'package:claudy/features/search/domain/models/place.dart';
import 'package:claudy/features/search/domain/repositories/place_search_repository.dart';
import 'package:claudy/features/weather/domain/models/geo_coordinate.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final placeSearchRepositoryProvider = Provider<PlaceSearchRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return OpenWeatherPlaceSearchRepository(dio: dio);
});

class OpenWeatherPlaceSearchRepository implements PlaceSearchRepository {
  OpenWeatherPlaceSearchRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  @override
  Future<AppResult<List<Place>>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      return const Failure(ValidationFailure(message: 'Query too short'));
    }
    if (AppConfig.openWeatherApiKey.isEmpty) {
      return _searchWithOpenMeteo(trimmed);
    }

    try {
      final response = await _dio.get<List<dynamic>>(
        'https://api.openweathermap.org/geo/1.0/direct',
        queryParameters: {'q': trimmed, 'limit': 10, 'appid': AppConfig.openWeatherApiKey},
      );

      final data = response.data;
      if (data == null) throw const MappingException('Empty geocoding response');

      final results = <Place>[];
      for (final item in data) {
        if (item is! Map) continue;
        final name = item['name'];
        final country = item['country'];
        final lat = item['lat'];
        final lon = item['lon'];
        if (name is! String || name.isEmpty) continue;
        if (country is! String || country.isEmpty) continue;
        if (lat is! num || lon is! num) continue;
        results.add(
          Place(
            name: name,
            country: country,
            coordinate: GeoCoordinate(lat: lat.toDouble(), lon: lon.toDouble()),
          ),
        );
      }
      return Success(results);
    } catch (e) {
      return Failure(_mapError(e));
    }
  }

  Future<AppResult<List<Place>>> _searchWithOpenMeteo(String query) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://geocoding-api.open-meteo.com/v1/search',
        queryParameters: {'name': query, 'count': 10, 'language': 'en', 'format': 'json'},
      );

      final body = response.data;
      if (body == null) throw const MappingException('Empty geocoding response');

      final items = body['results'];
      if (items is! List) {
        return const Success(<Place>[]);
      }

      final results = <Place>[];
      for (final item in items) {
        if (item is! Map) continue;
        final name = item['name'];
        final country = item['country'];
        final countryCode = item['country_code'];
        final lat = item['latitude'];
        final lon = item['longitude'];
        if (name is! String || name.isEmpty) continue;
        if (lat is! num || lon is! num) continue;

        final countryLabel = switch (country) {
          String value when value.isNotEmpty => value,
          _ => countryCode is String && countryCode.isNotEmpty ? countryCode : '-',
        };

        results.add(
          Place(
            name: name,
            country: countryLabel,
            coordinate: GeoCoordinate(lat: lat.toDouble(), lon: lon.toDouble()),
          ),
        );
      }
      return Success(results);
    } catch (e) {
      return Failure(_mapError(e));
    }
  }

  AppFailure _mapError(Object e) {
    if (e is DioException) {
      return NetworkFailure(message: e.message ?? 'Network error');
    }
    return UnknownFailure(message: e.toString());
  }
}
