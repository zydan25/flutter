import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:dynamic_flutter_app/data/local/cache_coordinator.dart';
import 'package:dynamic_flutter_app/data/local/drift_store.dart';
import 'package:dynamic_flutter_app/data/local/runtime_repository.dart';

void main() {
  late Directory temp;
  late DriftStore store;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('cache_coord_test_');
    store = DriftStore(File('${temp.path}/runtime.sqlite'));
    await store.open();
  });

  tearDown(() async {
    await store.close();
    await temp.delete(recursive: true);
  });

  test('cache-first returns local value without network fetch', () async {
    final repository = RuntimeRepository<Map<String, dynamic>>(
      store: store,
      resourceId: 'home',
      fromJson: (json) => json,
      toJson: (value) => value,
    );
    await repository.put(value: {'title': 'Local'}, version: 1, checksum: 'x');

    final coordinator = CacheCoordinator<Map<String, dynamic>>(
      repository: repository,
    );
    var fetched = false;
    final value = await coordinator.readAndRevalidate(
      fetch: () async {
        fetched = true;
        return {'title': 'Network'};
      },
    );

    expect(value, {'title': 'Local'});
    expect(fetched, isFalse);
  });
}
