import '../local/cache_policy.dart';
import '../local/drift_store.dart';

class ResourceSnapshot {
  const ResourceSnapshot({
    required this.id,
    required this.version,
    required this.checksum,
    required this.payload,
    this.updatedAt,
  });

  final String id;
  final int version;
  final String checksum;
  final Map<String, dynamic> payload;
  final DateTime? updatedAt;

  bool isFresh(CachePolicy policy, {DateTime? now}) =>
      policy.isFresh(updatedAt, now ?? DateTime.now());
}

class ResourceRepository {
  ResourceRepository(this.store, {this.cachePolicy = const CachePolicy()});

  final DriftStore store;
  final CachePolicy cachePolicy;

  Future<Map<String, dynamic>?> getLocal(String resourceId) =>
      store.resource(resourceId);

  Future<ResourceSnapshot?> snapshot(String resourceId) async {
    final row = await store.resourceMetadata(resourceId);
    if (row == null) return null;
    final payload = row['payload'];
    if (payload is! String) return null;
    return ResourceSnapshot(
      id: '${row['resource_id']}',
      version: int.tryParse('${row['version'] ?? 0}') ?? 0,
      checksum: '${row['checksum'] ?? ''}',
      payload: (await store.resource(resourceId)) ?? const {},
      updatedAt: DateTime.tryParse('${row['updated_at'] ?? ''}'),
    );
  }

  Future<Map<String, dynamic>> allLocal() => store.allResources();

  Future<void> saveLocal({
    required String resourceId,
    required int version,
    required String checksum,
    required Map<String, dynamic> data,
    String? updatedAt,
  }) {
    return store.saveResource(
      id: resourceId,
      version: version,
      checksum: checksum,
      payload: data,
      updatedAt: updatedAt,
    );
  }

  Future<void> updateLocalAndQueue({
    required String operationId,
    required String resourceId,
    required String operation,
    required Map<String, dynamic> data,
    String? entityId,
    int? baseVersion,
  }) async {
    await saveLocal(
      resourceId: resourceId,
      version: baseVersion ?? 0,
      checksum: '',
      data: data,
      updatedAt: DateTime.now().toUtc().toIso8601String(),
    );
    await store.enqueue(
      operationId: operationId,
      entity: resourceId,
      entityId: entityId,
      operation: operation,
      payload: data,
      baseVersion: baseVersion,
    );
  }
}
