class LogBuffer {
  static final List<Map<String, Object?>> _entries = [];
  static const int _max = 500;

  static void record(String level, String message, {Object? error, StackTrace? stackTrace}) {
    _entries.add({
      'ts': DateTime.now().toIso8601String(),
      'level': level,
      'message': message,
      if (error != null) 'error': '$error',
      if (stackTrace != null) 'stack': '$stackTrace',
    });
    if (_entries.length > _max) {
      _entries.removeAt(0);
    }
  }

  static List<Map<String, Object?>> snapshot() {
    return List<Map<String, Object?>>.unmodifiable(_entries);
  }
}
