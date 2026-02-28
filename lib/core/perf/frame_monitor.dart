import 'package:flutter/scheduler.dart';
import 'package:claudy/core/logging/app_logger.dart';

class FrameMonitor {
  static bool _started = false;
  static int _jankCount = 0;
  static double _worstMs = 0;

  static void start() {
    if (_started) return;
    _started = true;
    SchedulerBinding.instance.addTimingsCallback((timings) {
      for (final t in timings) {
        final ms = (t.totalSpan.inMicroseconds) / 1000.0;
        if (ms > 16.7) {
          _jankCount += 1;
          if (ms > _worstMs) _worstMs = ms;
          AppLogger.warn('Frame jank detected: ${ms.toStringAsFixed(2)}ms');
        }
      }
    });
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
  }
}
