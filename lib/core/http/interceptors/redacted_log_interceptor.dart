import 'package:claudy/core/logging/app_logger.dart';
import 'package:dio/dio.dart';

/// Minimal request/error logging that redacts secrets (e.g. `appid` query
/// parameters) before anything reaches the diagnostics LogBuffer.
class RedactedLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    AppLogger.info('HTTP ${options.method} ${_redact(options.uri)}');
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppLogger.warn(
      'HTTP ${err.response?.statusCode} ${_redact(err.requestOptions.uri)}',
      error: err.error,
    );
    handler.next(err);
  }

  static const _sensitiveQueryParams = {'appid', 'key', 'access_token'};

  static Uri _redact(Uri uri) {
    if (!uri.queryParameters.keys.any(_sensitiveQueryParams.contains)) {
      return uri;
    }
    return uri.replace(
      queryParameters: {
        for (final entry in uri.queryParameters.entries)
          if (!_sensitiveQueryParams.contains(entry.key)) entry.key: entry.value,
      },
    );
  }
}
