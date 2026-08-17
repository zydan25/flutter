class ResourceBindingEngine {
  const ResourceBindingEngine();

  dynamic bind(dynamic node, Map<String, dynamic> resources) {
    if (node is List) {
      return node.expand<dynamic>((item) {
        final bound = bind(item, resources);
        if (bound is List && item is Map && item.containsKey('for_each')) {
          return bound;
        }
        return [bound];
      }).toList();
    }
    if (node is! Map) return _interpolate(node, resources);

    final map = node.cast<String, dynamic>();
    final each = map['for_each']?.toString();
    if (each != null && each.isNotEmpty) {
      final values = _resolve(each, resources);
      final template = map['item_template'];
      if (values is List && template is Map) {
        return values
            .map((value) => bind(template, {...resources, 'item': value}))
            .toList();
      }
    }

    final result = <String, dynamic>{};
    for (final entry in map.entries) {
      if (entry.key == 'item_template' || entry.key == 'for_each') continue;
      final value = bind(entry.value, resources);
      result[entry.key] = value;
    }
    return result;
  }

  dynamic _interpolate(dynamic value, Map<String, dynamic> resources) {
    if (value is! String || !value.contains(r'${')) return value;
    final exact = RegExp(r'^\$\{([^}]+)\}$').firstMatch(value);
    if (exact != null) return _resolve(exact.group(1)!, resources);
    return value.replaceAllMapped(
      RegExp(r'\$\{([^}]+)\}'),
      (match) => '${_resolve(match.group(1)!, resources) ?? ''}',
    );
  }

  dynamic _resolve(String path, Map<String, dynamic> data) {
    dynamic current = data;
    for (final segment in path.split('.')) {
      if (current is Map && current.containsKey(segment)) {
        current = current[segment];
      } else if (current is List) {
        final index = int.tryParse(segment);
        if (index == null || index < 0 || index >= current.length) return null;
        current = current[index];
      } else {
        return null;
      }
    }
    return current;
  }
}
