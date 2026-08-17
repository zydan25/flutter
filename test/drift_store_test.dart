import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:dynamic_flutter_app/data/local/drift_store.dart';

void main() {
  late Directory temp;
  late DriftStore store;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('runtime_store_test_');
    store = DriftStore(File('${temp.path}/runtime.sqlite'));
    await store.open();
  });

  tearDown(() async {
    await store.close();
    await temp.delete(recursive: true);
  });

  test('persists resources, retries and conflicts in sqlite', () async {
    await store.saveResource(
      id: 'customers',
      version: 3,
      checksum: 'abc',
      payload: {'items': [1, 2]},
    );
    expect((await store.resourceMetadata('customers'))?['version'], 3);

    await store.enqueue(
      operationId: 'op-1',
      entity: 'customers',
      operation: 'update',
      payload: {'id': 1},
    );
    await store.scheduleRetry(
      'op-1',
      retryCount: 1,
      nextRetryAt: DateTime.now().subtract(const Duration(seconds: 1)),
      error: 'temporary',
    );
    expect((await store.pendingOperations()).single['retry_count'], 1);

    await store.saveConflict(
      operationId: 'op-1',
      entity: 'customers',
      localPayload: {'id': 1, 'name': 'local'},
      serverPayload: {'id': 1, 'name': 'server'},
      baseVersion: 2,
      serverVersion: 3,
    );
    expect(await store.pendingConflictCount(), 1);
    await store.resolveConflict(operationId: 'op-1', resolution: 'server_wins');
    expect(await store.pendingConflictCount(), 0);
  });
}
