import 'package:flutter_test/flutter_test.dart';
import 'package:dynamic_flutter_app/permissions/permission_service.dart';

void main() {
  test('evaluates permissions and feature flags', () {
    final service = PermissionService(
      grants: {
        'permissions': ['users.read'],
        'feature_flags': {'new_home': true},
      },
    );

    expect(service.can('users.read'), isTrue);
    expect(service.can('users.delete'), isFalse);
    expect(service.featureEnabled('new_home'), isTrue);
    expect(service.canNavigate({'permission': 'users.read'}), isTrue);
    expect(service.canExecuteAction({'permission': 'users.delete'}), isFalse);

    service.update({'permissions': ['users.delete']});
    expect(service.can('users.read'), isFalse);
    expect(service.can('users.delete'), isTrue);
  });
}
