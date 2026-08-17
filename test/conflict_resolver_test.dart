import 'package:flutter_test/flutter_test.dart';

import 'package:dynamic_flutter_app/sync/conflict_resolver.dart';

void main() {
  const base = SyncConflict(
    operationId: 'op-1',
    entity: 'customer',
    entityId: '42',
    serverVersion: 7,
    clientVersion: 7,
    serverData: {'name': 'Server', 'status': 'active'},
    clientData: {'name': 'Client', 'phone': '777'},
  );

  test('server-wins resolution returns server snapshot', () {
    final result = const ConflictResolver().resolve(
      SyncConflict(
        operationId: base.operationId,
        entity: base.entity,
        entityId: base.entityId,
        serverVersion: base.serverVersion,
        clientVersion: base.clientVersion,
        serverData: base.serverData,
        clientData: base.clientData,
        resolution: ConflictResolution.serverWins,
      ),
    );
    expect(result['name'], 'Server');
  });

  test('merge resolution combines server and client values', () {
    final result = const ConflictResolver().resolve(
      SyncConflict(
        operationId: base.operationId,
        entity: base.entity,
        entityId: base.entityId,
        serverVersion: base.serverVersion,
        clientVersion: base.clientVersion,
        serverData: base.serverData,
        clientData: base.clientData,
        resolution: ConflictResolution.merge,
      ),
    );
    expect(result, {'name': 'Client', 'status': 'active', 'phone': '777'});
  });

  test('manual resolution refuses silent overwrite', () {
    expect(
      () => const ConflictResolver().resolve(base),
      throwsStateError,
    );
  });
}
