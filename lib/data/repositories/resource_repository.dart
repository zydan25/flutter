import '../local/drift_store.dart';

class ResourceRepository {
  ResourceRepository(this.store);

  final DriftStore store;

  Future<Map<String, dynamic>?> getLocal(String resourceId) =>
      store.resource(resourceId);

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
