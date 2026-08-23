import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:claudy/core/logging/app_logger.dart';

class FrameMonitor {
  static bool _started = false;
  static int _jankCount = 0;
  static double _worstMs = 0;

  static int _windowJankCount = 0;
  static double _windowWorstMs = 0;
  static DateTime _windowStart = DateTime.now();

  /// One aggregate warning per window instead of one log per janky frame,
  /// so sustained jank cannot flood the diagnostics LogBuffer.
  static const _logWindow = Duration(seconds: 10);

  static void start() {
    if (_started) return;
    _started = true;
    SchedulerBinding.instance.addTimingsCallback((timings) {
      for (final t in timings) {
        final ms = (t.totalSpan.inMicroseconds) / 1000.0;
        if (ms > _jankThresholdMs) {
          _jankCount += 1;
          if (ms > _worstMs) _worstMs = ms;
          _windowJankCount += 1;
          if (ms > _windowWorstMs) _windowWorstMs = ms;
        }
      }
      _maybeLogWindow();
    });
  }

  /// Budget assumes a 60 Hz display; high-refresh devices simply report
  /// more benign frames as slow, which is acceptable for a diagnostic.
  static const double _jankThresholdMs = 16.7;

  static void _maybeLogWindow() {
    if (!kDebugMode && !kProfileMode) return;
    final now = DateTime.now();
    final elapsed = now.difference(_windowStart);
    if (elapsed < _logWindow) return;
    if (_windowJankCount > 0) {
      // Report the real span: after long idle gaps "last 10s" would be a lie.
      AppLogger.warn(
        'Frame jank: $_windowJankCount frames over '
        '${_windowWorstMs.toStringAsFixed(0)}ms in the last '
        '${elapsed.inSeconds}s',
      );
      _windowJankCount = 0;
      _windowWorstMs = 0;
    }
    _windowStart = now;
  }

  static Map<String, Object?> metrics() {
    return {
      'jankCount': _jankCount,
      'worstMs': _worstMs,
    };
  }

  static void reset() {
    _jankCount = 0;
    _worstMs = 0;
    _windowJankCount = 0;
    _windowWorstMs = 0;
    _windowStart = DateTime.now();
  }
}
