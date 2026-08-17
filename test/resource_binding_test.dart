import 'package:flutter_test/flutter_test.dart';

import 'package:dynamic_flutter_app/runtime/resource_binding.dart';

void main() {
  test('interpolates nested resource values', () {
    const binder = ResourceBindingEngine();
    final result = binder.bind(
      {'data': r'${customer.name}', 'id': r'${customer.id}'},
      {
        'customer': {'name': 'Zaidan', 'id': 42},
      },
    ) as Map<String, dynamic>;

    expect(result['data'], 'Zaidan');
    expect(result['id'], 42);
  });

  test('expands for_each templates into a list', () {
    const binder = ResourceBindingEngine();
    final result = binder.bind(
      {
        'for_each': 'customers',
        'item_template': {
          'type': 'text',
          'data': r'${item.name}',
        },
      },
      {
        'customers': [
          {'name': 'A'},
          {'name': 'B'},
        ],
      },
    ) as List<dynamic>;

    expect(result, [
      {'type': 'text', 'data': 'A'},
      {'type': 'text', 'data': 'B'},
    ]);
  });
}
