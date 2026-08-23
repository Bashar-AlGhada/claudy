import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RateLimitInterceptor extends Interceptor {
  static const _prefsKeyCooldowns = 'rate_limit.cooldown_until_by_host';

  /// Pre-per-host persisted value from older versions; removed on first load.
  static const _legacyPrefsKeyCooldown = 'rate_limit.cooldown_until_epoch_ms';

  /// Cooldowns are tracked per host so a 429 from one API (e.g. OpenWeather)
  /// never blocks unrelated hosts (Open-Meteo, reverse geocoding, search).
  final Map<String, DateTime> _cooldownUntilByHost = {};
  bool _prefsLoaded = false;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (!_prefsLoaded) {
      await _loadCooldownsFromPrefs();
    }
    final until = _cooldownUntilByHost[options.uri.host];
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
      final host = err.requestOptions.uri.host;
      // Clamp hostile/huge Retry-After values so one bad response cannot
      // block a host indefinitely.
      var retryAfter =
          _parseRetryAfter(err.response) ?? const Duration(minutes: 5);
      if (retryAfter < Duration.zero) retryAfter = Duration.zero;
      if (retryAfter > maxCooldown) retryAfter = maxCooldown;
      final until = DateTime.now().add(retryAfter);
      _cooldownUntilByHost[host] = until;
      unawaited(_persistCooldown(host, until));
    }
    handler.next(err);
  }

  static const maxCooldown = Duration(minutes: 15);

  Future<void> _loadCooldownsFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKeyCooldowns);
      if (raw != null) {
        final decoded =
            jsonDecode(raw) as Map<String, dynamic>;
        decoded.forEach((host, epochMs) {
          _cooldownUntilByHost[host] =
              DateTime.fromMillisecondsSinceEpoch(epochMs as int);
        });
      }
      await prefs.remove(_legacyPrefsKeyCooldown);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('RateLimitInterceptor: failed to load cooldowns: $e');
      }
    } finally {
      _prefsLoaded = true;
    }
  }

  Future<void> _persistCooldown(String host, DateTime until) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode({
        for (final entry in _cooldownUntilByHost.entries)
          entry.key: entry.value.millisecondsSinceEpoch,
      });
      await prefs.setString(_prefsKeyCooldowns, encoded);
    } catch (_) {
      // Persistence is best-effort; in-memory state still applies.
    }
  }

  Duration? _parseRetryAfter(Response<dynamic>? response) {
    if (response == null) return null;
    final header = response.headers.value('retry-after');
    if (header == null) return null;
    final seconds = int.tryParse(header);
    if (seconds != null) {
      if (seconds < 0) return null;
      return Duration(seconds: seconds);
    }
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
