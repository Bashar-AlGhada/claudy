import 'dart:developer' as developer;
import 'package:claudy/core/logging/log_buffer.dart';

class AppLogger {
  static void info(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(message, name: 'claudy', error: error, stackTrace: stackTrace);
    LogBuffer.record('INFO', message, error: error, stackTrace: stackTrace);
  }

  static void warn(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(message, name: 'claudy', level: 900, error: error, stackTrace: stackTrace);
    LogBuffer.record('WARN', message, error: error, stackTrace: stackTrace);
  }

  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(message, name: 'claudy', level: 1000, error: error, stackTrace: stackTrace);
    LogBuffer.record('ERROR', message, error: error, stackTrace: stackTrace);
  }
}
