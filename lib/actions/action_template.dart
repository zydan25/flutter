class ActionTemplate {
  const ActionTemplate._();

  static dynamic resolve(dynamic value, Map<String, dynamic> data) {
    if (value is String) return _resolveString(value, data);
    if (value is List) {
      return value.map((item) => resolve(item, data)).toList();
    }
    if (value is Map) {
      return value.map((key, item) => MapEntry(key, resolve(item, data)));
    }
    return value;
  }

  static String _resolveString(String value, Map<String, dynamic> data) {
    final exact = RegExp(r'^\$\{([^}]+)\}$').firstMatch(value);
    if (exact != null) {
      return '${_lookup(exact.group(1)!, data) ?? ''}';
    }

    return value.replaceAllMapped(
      RegExp(r'\$\{([^}]+)\}'),
      (match) => '${_lookup(match.group(1)!, data) ?? ''}',
    );
  }

  static dynamic _lookup(String path, Map<String, dynamic> data) {
    dynamic current = data;
    for (final segment in path.split('.')) {
      if (current is Map<String, dynamic> && current.containsKey(segment)) {
        current = current[segment];
      } else if (current is Map && current.containsKey(segment)) {
        current = current[segment];
      } else {
        return null;
      }
    }
    return current;
  }
}
