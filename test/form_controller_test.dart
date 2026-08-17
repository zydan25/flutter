import 'package:flutter_test/flutter_test.dart';
import 'package:dynamic_flutter_app/runtime/form_controller.dart';
import 'package:dynamic_flutter_app/runtime/form_runtime.dart';

void main() {
  test('tracks values, visibility, validation and submission mapping', () {
    final spec = DynamicFormSpec.fromJson({
      'id': 'profile',
      'fields': [
        {'name': 'name', 'type': 'text', 'required': true},
        {
          'name': 'age',
          'type': 'number',
          'min': 18,
          'visible_when': {'field': 'name', 'equals': 'Zaidan'},
        },
      ],
    });
    final controller = DynamicFormController(
      spec,
      initialValues: {'name': 'Zaidan'},
    );

    expect(controller.isVisible('age'), isTrue);
    controller.setValue('age', 20);
    expect(controller.validate(), isEmpty);
    expect(
      controller.submission(mapping: {'displayName': r'${name}', 'years': r'${age}'}),
      equals({'displayName': 'Zaidan', 'years': 20}),
    );

    controller.setValue('name', 'Other');
    controller.removeHiddenValues();
    expect(controller.values.containsKey('age'), isFalse);
  });
}
