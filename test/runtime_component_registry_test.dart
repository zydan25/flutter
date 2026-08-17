import 'package:flutter_test/flutter_test.dart';
import 'package:dynamic_flutter_app/runtime/runtime_component_registry.dart';

void main() {
  test('builds registered runtime component', () {
    final registry = RuntimeComponentRegistry(
      builders: {
        'hello': (definition) => {
          'type': 'text',
          'data': 'Hello ${definition['name']}',
        },
      },
    );

    final result = registry.expandNode({
      'type': 'runtime_component',
      'name': 'hello',
      'name': 'Runtime',
    });

    expect(result['type'], 'text');
    expect(result['data'], 'Hello Runtime');
  });
}
