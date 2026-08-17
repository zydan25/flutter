import 'package:flutter_test/flutter_test.dart';

import 'package:dynamic_flutter_app/core/runtime_config.dart';
import 'package:dynamic_flutter_app/permissions/permission_service.dart';

void main() {
  test('runtime contract exposes versioned endpoints', () {
    expect(RuntimeConfig.runtimeVersion, '2.0.0');
    expect(RuntimeConfig.legacyConfigPath, '/api/app-config');
    expect(RuntimeConfig.syncPath, '/runtime/sync');
  });

  test('permission service keeps backend as authority', () {
    final service = PermissionService(grants: {
      'permissions': ['customers.read'],
      'feature_flags': {'new_home': true},
    });
    expect(service.can('customers.read'), isTrue);
    expect(service.can('customers.delete'), isFalse);
    expect(service.featureEnabled('new_home'), isTrue);
  });
}
