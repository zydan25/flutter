import 'package:flutter_test/flutter_test.dart';

import 'package:dynamic_flutter_app/actions/action_template.dart';
import 'package:dynamic_flutter_app/core/runtime_config.dart';
import 'package:dynamic_flutter_app/permissions/permission_service.dart';
import 'package:dynamic_flutter_app/runtime/runtime_contract.dart';

void main() {
  test('runtime contract exposes versioned endpoints', () {
    expect(RuntimeConfig.runtimeVersion, '2.0.0');
    expect(RuntimeConfig.legacyConfigPath, '/api/app-config');
    expect(RuntimeConfig.syncPath, '/runtime/sync');
  });

  test('permission service keeps backend as authority', () {
    final service = PermissionService(
      grants: {
        'permissions': ['customers.read'],
        'feature_flags': {'new_home': true},
      },
    );
    expect(service.can('customers.read'), isTrue);
    expect(service.can('customers.delete'), isFalse);
    expect(service.featureEnabled('new_home'), isTrue);
  });

  test('manifest validator accepts a versioned STAC screen', () {
    const validator = RuntimeContractValidator();
    expect(
      () => validator.validate({
        'schema_version': 1,
        'home_screen': 'home',
        'screens': [
          {
            'name': 'home',
            'stac': {'type': 'scaffold'},
          },
        ],
      }),
      returnsNormally,
    );
  });

  test('manifest validator rejects unsupported schema versions', () {
    const validator = RuntimeContractValidator(supportedSchemaVersion: 1);
    expect(
      () => validator.validate({'schema_version': 2}),
      throwsA(isA<RuntimeContractException>()),
    );
  });

  test('action templates resolve nested server data', () {
    final resolved = ActionTemplate.resolve(
      {
        'url': '/customers/${customer.id}',
        'body': {'name': r'${customer.name}'},
      },
      {
        'customer': {'id': 42, 'name': 'Zaidan'},
      },
    );

    expect(resolved, {
      'url': '/customers/42',
      'body': {'name': 'Zaidan'},
    });
  });
}
