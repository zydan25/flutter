import 'dart:convert';

import '../core/runtime_config.dart';
import '../data/api/api_client.dart';
import '../data/local/drift_store.dart';
import 'retry_policy.dart';
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
  SyncEngine({
    required this.api,
    required this.store,
    this.retryPolicy = const RetryPolicy(),
  });

  final ApiClient api;
  final DriftStore store;
  final RetryPolicy retryPolicy;

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

  Future<void> _hydrateRemoteRuntime({required Map<String, dynamic> bootstrap}) async {
    final manifestResponse = await _requestAllowingFallback(
      method: 'GET',
      path: RuntimeConfig.manifestPath,
    );
    if (manifestResponse == null || manifestResponse.statusCode != 200) {
      throw Exception('Runtime manifest request failed');
    }
    if (manifestResponse.data is! Map<String, dynamic>) {
      throw const FormatException('Runtime manifest returned invalid JSON');
    }

    final manifest = Map<String, dynamic>.from(
      manifestResponse.data as Map<String, dynamic>,
    );
    manifest['bootstrap'] = bootstrap;

    final resourcesResponse = await _requestAllowingFallback(
      method: 'GET',
      path: RuntimeConfig.resourcesPath,
    );
    if (resourcesResponse?.statusCode == 200 &&
        resourcesResponse?.data is Map<String, dynamic>) {
      manifest['resources'] = resourcesResponse!.data['resources'] ?? {};
    }
    await saveManifest(manifest);
  }

  Future<void> initialSync() async {
    if (await hasLocalSnapshot()) return;

    final response = await _requestAllowingFallback(
      method: 'GET',
      path: RuntimeConfig.bootstrapPath,
    );
    if (response != null && response.statusCode == 200 &&
        response.data is Map<String, dynamic>) {
      await _hydrateRemoteRuntime(
        bootstrap: Map<String, dynamic>.from(
          response.data as Map<String, dynamic>,
        ),
      );
      return;
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
              'retry_count': row['retry_count'] ?? 0,
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
        if (data is Map<String, dynamic> && data['results'] is List) {
          final parsed = SyncResponse.fromJson({
            'operations': data['results'],
            'resources': data['resources'] ?? const [],
          });
          for (final result in parsed.operations) {
            final row = pending.firstWhere(
              (item) => item['operation_id'] == result.operationId,
              orElse: () => <String, Object?>{},
            );
            if (row.isEmpty) continue;
            final operationId = row['operation_id'] as String;
            final retryCount = int.tryParse('${row['retry_count'] ?? 0}') ?? 0;
            switch (result.status) {
              case SyncOperationStatus.acknowledged:
                await store.markOperation(operationId, 'acknowledged');
                uploaded++;
                break;
              case SyncOperationStatus.conflict:
                await store.markOperation(operationId, 'conflict');
                await store.saveConflict(
                  operationId: operationId,
                  entity: '${row['entity']}',
                  entityId: row['entity_id']?.toString(),
                  baseVersion: int.tryParse('${row['base_version'] ?? ''}'),
                  serverVersion: result.serverVersion,
                  localPayload: (jsonDecode(row['payload'] as String) as Map)
                      .cast<String, dynamic>(),
                  serverPayload: result.conflictData ?? result.serverData,
                );
                conflicts++;
                break;
              case SyncOperationStatus.retry:
                if (retryPolicy.canRetry(retryCount)) {
                  final nextCount = retryCount + 1;
                  await store.scheduleRetry(
                    operationId,
                    retryCount: nextCount,
                    nextRetryAt: DateTime.now()
                        .toUtc()
                        .add(retryPolicy.delayFor(retryCount)),
                    error: result.message,
                  );
                } else {
                  await store.markOperation(operationId, 'rejected');
                  rejected++;
                }
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
        }
      }
    }

    final response = await _requestAllowingFallback(
      method: 'GET',
      path: RuntimeConfig.manifestPath,
    );
    if (response?.statusCode == 200 && response?.data is Map<String, dynamic>) {
      await _hydrateRemoteRuntime(
        bootstrap: const <String, dynamic>{},
      );
      return SyncResult(
        changed: 1,
        pendingUploaded: uploaded,
        conflicts: conflicts,
        retries: retries,
        rejected: rejected,
      );
    }

    final legacy = await _requestAllowingFallback(
      method: 'GET',
      path: RuntimeConfig.legacyConfigPath,
    );
    if (legacy == null || legacy.statusCode != 200) {
      throw Exception('Manual sync failed');
    }
    if (legacy.data is! Map<String, dynamic>) {
      throw const FormatException('Manual sync returned invalid JSON');
    }
    await saveManifest(legacy.data as Map<String, dynamic>);
    return SyncResult(
      changed: 1,
      pendingUploaded: uploaded,
      conflicts: conflicts,
      retries: retries,
      rejected: rejected,
    );
  }

  Future<void> saveManifest(Map<String, dynamic> manifest) async {
    final version = int.tryParse(
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
