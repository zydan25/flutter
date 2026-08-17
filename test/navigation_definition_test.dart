import 'package:flutter_test/flutter_test.dart';
import 'package:dynamic_flutter_app/navigation/navigation_definition.dart';

void main() {
  test('parses drawer, bottom navigation and deep links', () {
    final definition = NavigationDefinition.fromManifest({
      'navigation': {
        'drawer': [
          {'route': '/customers', 'label': 'Customers'},
        ],
        'bottom': [
          {'route': '/home', 'label': 'Home'},
        ],
        'deep_links': {
          '/customer': '/customers',
        },
      },
    });

    expect(definition.drawer.single.route, '/customers');
    expect(definition.bottom.single.label, 'Home');
    expect(definition.resolveDeepLink('/customer?id=7'), '/customers');
  });
}
