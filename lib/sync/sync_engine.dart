import 'dart:convert';

import '../core/runtime_config.dart';
import '../data/api/api_client.dart';
import '../data/local/drift_store.dart';
import 'sync_protocol.dart';

class SyncResult {
  const SyncResult({
    required this.changed,
    required this.pendingUploaded,
    this.conflicts = 0,
    this.retries = 0,
    this.rejected = 0,
  });

  final int changed;
  final int pendingUploaded;
  final int conflicts;
  final int retries;
  final int rejected;
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
    var conflicts = 0;
    var retries = 0;
    var rejected = 0;
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
        final data = response.data;
        if (data is Map<String, dynamic> && data['operations'] is List) {
          final parsed = SyncResponse.fromJson(data);
          for (final result in parsed.operations) {
            final row = pending.firstWhere(
              (item) => item['operation_id'] == result.operationId,
              orElse: () => <String, Object?>{},
            );
            if (row.isEmpty) continue;
            final operationId = row['operation_id'] as String;
            switch (result.status) {
              case SyncOperationStatus.acknowledged:
                await store.markOperation(operationId, 'acknowledged');
                uploaded++;
                final entity = row['entity']?.toString();
                if (entity != null && result.serverData != null) {
                  await store.saveResource(
                    id: entity,
                    version:
                        result.serverVersion ??
                        int.tryParse('${row['base_version'] ?? 0}') ??
                        0,
                    checksum: '${result.serverVersion ?? ''}',
                    payload: result.serverData!,
                    updatedAt: DateTime.now().toUtc().toIso8601String(),
                  );
                }
                break;
              case SyncOperationStatus.conflict:
                await store.markOperation(operationId, 'conflict');
                conflicts++;
                break;
              case SyncOperationStatus.retry:
                await store.markOperation(operationId, 'retry');
                retries++;
                break;
              case SyncOperationStatus.rejected:
                await store.markOperation(operationId, 'rejected');
                rejected++;
                break;
              case SyncOperationStatus.pending:
                await store.markOperation(operationId, 'pending');
                break;
            }
          }
          for (final resource in parsed.resources) {
            final id = resource['resource_id'] ?? resource['id'];
            if (id is String && id.isNotEmpty && resource['data'] is Map) {
              await store.saveResource(
                id: id,
                version: int.tryParse('${resource['version'] ?? 0}') ?? 0,
                checksum: '${resource['checksum'] ?? ''}',
                payload: (resource['data'] as Map).cast<String, dynamic>(),
                updatedAt: resource['updated_at']?.toString(),
              );
            }
          }
        }
      }
    }

    var response = await _requestAllowingFallback(
      method: 'GET',
      path: RuntimeConfig.manifestPath,
    );
    if (response?.statusCode == 200 && response?.data is Map<String, dynamic>) {
      await saveManifest(response!.data as Map<String, dynamic>);
      return SyncResult(
        changed: 1,
        pendingUploaded: uploaded,
        conflicts: conflicts,
        retries: retries,
        rejected: rejected,
      );
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
    return SyncResult(
      changed: 1,
      pendingUploaded: uploaded,
      conflicts: conflicts,
      retries: retries,
      rejected: rejected,
    );
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
