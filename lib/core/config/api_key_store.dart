import 'package:claudy/core/config/app_config.dart';
import 'package:claudy/core/http/dio_client.dart';
import 'package:claudy/core/logging/app_logger.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final apiKeyStoreProvider = Provider<ApiKeyStore>(
  (ref) => ApiKeyStore(dio: ref.watch(dioProvider)),
);

/// Resolved OpenWeatherMap key: a user-supplied key (secure storage, DPAPI on
/// Windows) takes precedence over the compile-time build flag.
final openWeatherApiKeyProvider = FutureProvider<String>(
  (ref) => ref.watch(apiKeyStoreProvider).read(),
);

enum ApiKeyValidation { valid, invalid, networkError }

/// Persists API keys outside of preferences so they never sit in plaintext
/// exports/backups, and validates them against a cheap OpenWeatherMap
/// endpoint before saving.
class ApiKeyStore {
  ApiKeyStore({required Dio dio, FlutterSecureStorage? storage})
      : _dio = dio,
        _storage = storage ?? const FlutterSecureStorage();

  static const _storageKey = 'security.openweathermap.api_key';

  final Dio _dio;
  final FlutterSecureStorage _storage;

  /// Resolves the effective key: secure-storage value first, then the
  /// build-time `OPENWEATHER_API_KEY` fallback. Never logs the value.
  Future<String> read() async {
    try {
      final stored = await _storage.read(key: _storageKey);
      if (stored != null && stored.trim().isNotEmpty) {
        return stored.trim();
      }
    } catch (e, s) {
      AppLogger.warn('Failed to read stored API key', error: e, stackTrace: s);
    }
    return AppConfig.openWeatherApiKey;
  }

  Future<bool> hasUserKey() async {
    try {
      final stored = await _storage.read(key: _storageKey);
      return stored != null && stored.trim().isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> save(String key) {
    return _storage.write(key: _storageKey, value: key.trim());
  }

  Future<void> clear() {
    return _storage.delete(key: _storageKey);
  }

  /// Cheap entitlement check against the geocoding endpoint.
  Future<ApiKeyValidation> validate(String key) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://api.openweathermap.org/geo/1.0/direct',
        queryParameters: {'q': 'London', 'limit': 1, 'appid': key},
        options: Options(
          receiveTimeout: const Duration(seconds: 6),
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      return response.statusCode == 200
          ? ApiKeyValidation.valid
          : ApiKeyValidation.invalid;
    } catch (_) {
      return ApiKeyValidation.networkError;
    }
  }
}
