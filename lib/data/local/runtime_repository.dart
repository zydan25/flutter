import 'dart:convert';

import 'drift_store.dart';

/// Typed repository boundary used by server-driven resources.
///
/// The runtime stays generic: each resource supplies its own decoder and
/// optional encoder while Drift remains the durable offline source of truth.
class RuntimeRepository<T> {
  RuntimeRepository({
    required this.store,
    required this.resourceId,
    required this.fromJson,
    this.toJson,
  });

  final DriftStore store;
  final String resourceId;
  final T Function(Map<String, dynamic> json) fromJson;
  final Map<String, dynamic> Function(T value)? toJson;

  Future<T?> get() async {
    final payload = await store.resource(resourceId);
    if (payload == null) return null;
    return fromJson(payload);
  }

  Future<void> put({
    required T value,
    required int version,
    required String checksum,
    String? updatedAt,
  }) async {
    final encoder = toJson;
    if (encoder == null) {
      throw StateError('Repository is read-only: no encoder was supplied');
    }
    await store.saveResource(
      id: resourceId,
      version: version,
      checksum: checksum,
      payload: encoder(value),
      updatedAt: updatedAt,
    );
  }

  Future<Map<String, Object?>?> metadata() => store.resourceMetadata(resourceId);

  Future<void> queueMutation({
    required String operationId,
    required String operation,
    required Map<String, dynamic> payload,
    String? entityId,
    int? baseVersion,
  }) =>
      store.enqueue(
        operationId: operationId,
        entity: resourceId,
        entityId: entityId,
        operation: operation,
        payload: payload,
        baseVersion: baseVersion,
      );

  String encodeValue(T value) {
    final encoder = toJson;
    if (encoder == null) {
      throw StateError('Repository is read-only: no encoder was supplied');
    }
    return jsonEncode(encoder(value));
  }
}
