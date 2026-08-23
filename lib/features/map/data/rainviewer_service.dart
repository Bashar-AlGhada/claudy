import 'package:claudy/core/http/dio_client.dart';
import 'package:claudy/core/logging/app_logger.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final rainViewerProvider = Provider<RainViewerService>(
  (ref) => RainViewerService(dio: ref.watch(dioProvider)),
);

/// Fetches the latest radar/precipitation frame from RainViewer's free API
/// (no key required) and turns it into a flutter_map tile URL template.
///
/// Also probes OpenWeatherMap tile layers: OWM answers unauthorized or
/// unentitled requests with HTTP 401 *and a tiny PNG whose pixels contain
/// the error text*, which flutter_map would happily render as map tiles.
/// Probing byte size separates real tiles from those placeholders.
class RainViewerService {
  RainViewerService({required Dio dio}) : _dio = dio;

  static const _metaUrl = 'https://api.rainviewer.com/public/weather-maps.json';

  /// Frames refresh roughly every 10 minutes; cache the URL a bit shorter.
  static const _cacheTtl = Duration(minutes: 4);

  /// Real OWM tiles are kilobytes; error placeholders are ~100 bytes.
  static const _minRealTileBytes = 500;

  final Dio _dio;
  String? _cachedUrl;
  DateTime? _fetchedAt;
  Future<String?>? _inFlight;
  final Map<String, Future<bool>> _owmProbes = {};

  /// Tile template for the most recent past radar frame, or null when the
  /// service is unreachable. Concurrent callers share one request.
  Future<String?> latestRadarFrameUrl() {
    final now = DateTime.now();
    final cached = _cachedUrl;
    if (cached != null && _fetchedAt != null && now.difference(_fetchedAt!) < _cacheTtl) {
      return Future.value(cached);
    }
    return _inFlight ??= _fetch().whenComplete(() => _inFlight = null);
  }

  /// True when [layer] (e.g. `temp_new`) actually serves tiles for the
  /// configured key. Result cached per layer for the session.
  Future<bool> owmLayerAvailable(String layer, String apiKey) {
    return _owmProbes.putIfAbsent(layer, () async {
      final zoom = await _discoverOwmMaxZoom(layer, apiKey);
      return zoom != null;
    });
  }  /// Finds the highest zoom level whose tiles are real for this key/plan.
  /// OpenWeatherMap answers out-of-entitlement zooms with placeholder PNGs,
  /// so callers must clamp [TileLayer.maxNativeZoom] to this value.
  Future<int?> discoverOwmMaxNativeZoom(String layer, String apiKey) {
    final cacheKey = '$layer|$apiKey';
    return _owmMaxZoomCache.putIfAbsent(
      cacheKey,
      () => _discoverOwmMaxZoom(layer, apiKey),
    );
  }

  final Map<String, Future<int?>> _owmMaxZoomCache = {};

  Future<int?> _discoverOwmMaxZoom(String layer, String apiKey) async {
    const floor = 5;
    const ceiling = 19;
    for (var zoom = ceiling; zoom >= floor; zoom--) {
      if (await _owmTileIsReal(layer, apiKey, zoom)) {
        if (zoom < ceiling) {
          AppLogger.warn('OWM layer "$layer" capped at native zoom $zoom by plan');
        }
        return zoom;
      }
    }
    AppLogger.warn('OWM layer "$layer" unavailable at any probed zoom');
    return null;
  }

  Future<bool> _owmTileIsReal(String layer, String apiKey, int zoom) async {
    try {
      final response = await _dio.get<List<int>>(
        'https://tile.openweathermap.org/map/$layer/$zoom/136/87.png',
        queryParameters: {'appid': apiKey},
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(seconds: 5),
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      if (response.statusCode != 200) {
        return false;
      }
      // Real tiles are kilobytes; rejection placeholders are ~100 bytes of
      // rendered error text.
      return (response.data?.length ?? 0) >= _minRealTileBytes;
    } catch (_) {
      return false;
    }
  }

  Future<String?> _fetch() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        _metaUrl,
        options: Options(receiveTimeout: const Duration(seconds: 5)),
      );
      final data = response.data;
      final host = data?['host']?.toString();
      final radar = data?['radar'];
      final past = radar is Map ? radar['past'] : null;
      if (host == null || host.isEmpty || past is! List || past.isEmpty) {
        return null;
      }
      final frame = past.last as Map?;
      final path = frame?['path']?.toString();
      if (path == null || path.isEmpty) return null;

      final url = '$host$path/256/{z}/{x}/{y}/2/1_1.png';
      _cachedUrl = url;
      _fetchedAt = DateTime.now();
      return url;
    } catch (e, s) {
      AppLogger.warn('RainViewer frame fetch failed', error: e, stackTrace: s);
      return null;
    }
  }
}
