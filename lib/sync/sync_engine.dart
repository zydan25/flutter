import 'dart:convert';

import '../core/runtime_config.dart';
import '../data/api/api_client.dart';
import '../data/local/drift_store.dart';

class SyncResult {
  const SyncResult({required this.changed, required this.pendingUploaded});
  final int changed;
  final int pendingUploaded;
}

class SyncEngine {
  SyncEngine({required this.api, required this.store});

  final ApiClient api;
  final DriftStore store;

  Future<bool> hasLocalSnapshot() async =>
      (await store.meta('manifest_present')) == '1';

  Future<dynamic> _requestAllowingFallback({
    required String method,
    required String path,
    dynamic body,
  }) async {
    try {
      return await api.request(method: method, path: path, body: body);
    } catch (_) {
      return null;
    }
  }

  Future<void> initialSync() async {
    if (await hasLocalSnapshot()) return;

    final response = await _requestAllowingFallback(
      method: 'GET',
      path: RuntimeConfig.bootstrapPath,
    );
    if (response != null && response.statusCode == 200) {
      final data = response.data;
      if (data is Map<String, dynamic>) {
        await saveManifest(data);
        return;
      }
    }

    final legacy = await _requestAllowingFallback(
      method: 'GET',
      path: RuntimeConfig.legacyConfigPath,
    );
    if (legacy == null || legacy.statusCode != 200) {
      throw Exception('Initial bootstrap failed');
    }
    final data = legacy.data;
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Initial bootstrap returned invalid JSON');
    }
    await saveManifest(data);
  }

  Future<SyncResult> manualSync() async {
    var uploaded = 0;
    final pending = await store.pendingOperations();
    if (pending.isNotEmpty) {
      final ops = pending
          .map(
            (row) => {
              'operation_id': row['operation_id'],
              'entity': row['entity'],
              'entity_id': row['entity_id'],
              'operation': row['operation'],
              'payload': jsonDecode(row['payload'] as String),
              'base_version': row['base_version'],
            },
          )
          .toList();
      final response = await _requestAllowingFallback(
        method: 'POST',
        path: RuntimeConfig.syncPath,
        body: {'operations': ops},
      );
      if (response != null && response.statusCode == 200) {
        for (final row in pending) {
          await store.markOperation(
            row['operation_id'] as String,
            'acknowledged',
          );
          uploaded++;
        }
      }
    }

    var response = await _requestAllowingFallback(
      method: 'GET',
      path: RuntimeConfig.manifestPath,
    );
    if (response?.statusCode == 200 && response?.data is Map<String, dynamic>) {
      await saveManifest(response!.data as Map<String, dynamic>);
      return SyncResult(changed: 1, pendingUploaded: uploaded);
    }

    response = await _requestAllowingFallback(
      method: 'GET',
      path: RuntimeConfig.legacyConfigPath,
    );
    if (response == null || response.statusCode != 200) {
      throw Exception('Manual sync failed');
    }
    if (response.data is! Map<String, dynamic>) {
      throw const FormatException('Manual sync returned invalid JSON');
    }
    await saveManifest(response.data as Map<String, dynamic>);
    return SyncResult(changed: 1, pendingUploaded: uploaded);
  }

  Future<void> saveManifest(Map<String, dynamic> manifest) async {
    final version =
        int.tryParse(
          '${manifest['version'] ?? manifest['manifest_version'] ?? 0}',
        ) ??
        0;
    final checksum = '${manifest['checksum'] ?? version}';
    await store.saveResource(
      id: 'runtime_manifest',
      version: version,
      checksum: checksum,
      payload: manifest,
      updatedAt: DateTime.now().toUtc().toIso8601String(),
    );
    await store.setMeta('manifest_present', '1');
    await store.setMeta('manifest_version', '$version');
    await store.setMeta('last_sync', DateTime.now().toUtc().toIso8601String());
  }

  Future<Map<String, dynamic>?> localManifest() =>
      store.resource('runtime_manifest');
}
