import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:dynamic_flutter_app/data/local/drift_store.dart';
import 'package:dynamic_flutter_app/settings/diagnostics_service.dart';

void main() {
  test('self-test validates sqlite and API configuration', () async {
    final temp = await Directory.systemTemp.createTemp('diagnostics_test_');
    final store = DriftStore(File('${temp.path}/runtime.sqlite'));
    await store.open();
    addTearDown(() async {
      await store.close();
      await temp.delete(recursive: true);
    });

    final checks = await DiagnosticsService(store).selfTest();
    expect(checks.any((check) => check.name == 'SQLite' && check.ok), isTrue);
    expect(checks.any((check) => check.name == 'API configuration' && check.ok), isTrue);
  });
}
