import 'package:flutter_test/flutter_test.dart';
import 'package:dynamic_flutter_app/runtime/remote_option_provider.dart';

void main() {
  test('maps option value, label and extra data', () {
    final option = RemoteOption.fromJson(
      {
        'id': 10,
        'name': 'YemenNet',
      },
      valueKey: 'id',
      labelKey: 'name',
    );

    expect(option.value, 10);
    expect(option.label, 'YemenNet');
    expect(option.extra['id'], 10);
  });
}
