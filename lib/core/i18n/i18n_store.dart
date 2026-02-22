class I18nStore {
  static Map<String, Map<String, String>>? _keys;

  static void setKeys(Map<String, Map<String, String>> keys) {
    _keys = keys;
  }

  static Map<String, Map<String, String>> get keys {
    final current = _keys;
    if (current == null) {
      return const {
        'en': {},
      };
    }
    return current;
  }
}

