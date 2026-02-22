import 'dart:developer' as developer;

class AppLogger {
  static void info(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(message, name: 'claudy', error: error, stackTrace: stackTrace);
  }

  static void warn(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(message, name: 'claudy', level: 900, error: error, stackTrace: stackTrace);
  }

  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(message, name: 'claudy', level: 1000, error: error, stackTrace: stackTrace);
  }
}

