import 'dart:async';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RateLimitInterceptor extends Interceptor {
  static const _prefsKeyCooldownUntilEpochMs =
      'rate_limit.cooldown_until_epoch_ms';

  DateTime? _cooldownUntil;
  bool _prefsLoaded = false;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (!_prefsLoaded) {
      await _loadCooldownFromPrefs();
    }
    final until = _cooldownUntil;
    if (until != null) {
      final now = DateTime.now();
      if (now.isBefore(until)) {
        handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.unknown,
            error: RateLimitActiveException(until.difference(now)),
          ),
        );
        return;
      }
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 429) {
      final retryAfter = _parseRetryAfter(err.response) ?? const Duration(minutes: 5);
      _cooldownUntil = DateTime.now().add(retryAfter);
      unawaited(_persistCooldown(_cooldownUntil));
    }
    handler.next(err);
  }

  Future<void> _loadCooldownFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final epoch = prefs.getInt(_prefsKeyCooldownUntilEpochMs);
      if (epoch != null) {
        _cooldownUntil = DateTime.fromMillisecondsSinceEpoch(epoch);
      }
    } finally {
      _prefsLoaded = true;
    }
  }

  Future<void> _persistCooldown(DateTime? until) async {
    final prefs = await SharedPreferences.getInstance();
    if (until == null) {
      await prefs.remove(_prefsKeyCooldownUntilEpochMs);
      return;
    }
    await prefs.setInt(_prefsKeyCooldownUntilEpochMs, until.millisecondsSinceEpoch);
  }

  Duration? _parseRetryAfter(Response<dynamic>? response) {
    if (response == null) return null;
    final header = response.headers.value('retry-after');
    if (header == null) return null;
    final seconds = int.tryParse(header);
    if (seconds != null) return Duration(seconds: seconds);
    final date = DateTime.tryParse(header);
    if (date == null) return null;
    final delta = date.difference(DateTime.now());
    if (delta.isNegative) return null;
    return delta;
  }
}

class RateLimitActiveException implements Exception {
  const RateLimitActiveException(this.remaining);
  final Duration remaining;
}
