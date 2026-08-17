typedef RuntimeComponentBuilder = Map<String, dynamic> Function(
  Map<String, dynamic> definition,
);

class RuntimeComponentRegistry {
  RuntimeComponentRegistry({Map<String, RuntimeComponentBuilder>? builders})
    : _builders = {...?builders};

  final Map<String, RuntimeComponentBuilder> _builders;

  void register(String name, RuntimeComponentBuilder builder) {
    if (name.trim().isEmpty) {
      throw ArgumentError.value(name, 'name', 'Component name cannot be empty');
    }
    _builders[name] = builder;
  }

  bool contains(String name) => _builders.containsKey(name);

  Map<String, dynamic> build(Map<String, dynamic> definition) {
    final name = definition['name']?.toString() ?? definition['component']?.toString();
    if (name == null || name.isEmpty) {
      throw ArgumentError('runtime_component requires a name');
    }
    final builder = _builders[name];
    if (builder == null) {
      throw UnsupportedError('Unknown runtime component: $name');
    }
    return builder(definition);
  }

  Map<String, dynamic> expandNode(Map<String, dynamic> node) {
    if ('${node['type'] ?? ''}' != 'runtime_component') {
      return node;
    }
    return build(node);
  }
}
