import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:dynamic_flutter_app/data/local/drift_store.dart';
import 'package:dynamic_flutter_app/data/local/runtime_repository.dart';

void main() {
  late Directory temp;
  late DriftStore store;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('typed_repo_test_');
    store = DriftStore(File('${temp.path}/runtime.sqlite'));
    await store.open();
  });

  tearDown(() async {
    await store.close();
    await temp.delete(recursive: true);
  });

  test('reads and writes typed resource payloads', () async {
    final repository = RuntimeRepository<Map<String, dynamic>>(
      store: store,
      resourceId: 'profile',
      fromJson: (json) => json,
      toJson: (value) => value,
    );

    await repository.put(
      value: {'name': 'Zaidan'},
      version: 2,
      checksum: 'abc',
    );

    expect(await repository.get(), {'name': 'Zaidan'});
    expect((await repository.metadata())?['version'], 2);
    expect(repository.encodeValue({'ok': true}), '{"ok":true}');
  });
}
