import 'package:flutter_test/flutter_test.dart';
import 'package:dynamic_flutter_app/navigation/navigation_definition.dart';

void main() {
  test('parses drawer, bottom navigation, tabs, permissions and deep links', () {
    final definition = NavigationDefinition.fromManifest({
      'navigation': {
        'drawer': [
          {'route': '/home', 'label': 'Home', 'permission': 'home.read'},
        ],
        'bottom': [
          {'route': '/home', 'label': 'Home'},
          {'route': '/profile', 'label': 'Profile'},
        ],
        'tabs': [
          {'route': '/overview', 'label': 'Overview'},
          {'route': '/activity', 'label': 'Activity'},
        ],
        'deep_links': {'/users': '/profile'},
      },
    });

    expect(definition.drawer.single.permission, 'home.read');
    expect(definition.bottom.length, 2);
    expect(definition.tabs.length, 2);
    expect(definition.resolveDeepLink('/users?id=10'), '/profile');
    expect(definition.resolveDeepLink('/unknown'), isNull);
  });
}
