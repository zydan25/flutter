import '../local/drift_store.dart';

class RuntimeRepository<T> {
  RuntimeRepository({required this.store, required this.decode});

  final DriftStore store;
  final T Function(Map<String, dynamic> json) decode;

  Future<T?> get(String resourceId) async {
    final value = await store.resource(resourceId);
    return value == null ? null : decode(value);
  }

  Future<List<T>> getAll() async {
    final values = await store.allResources();
    return values.values
        .whereType<Map>()
        .map((value) => decode(value.cast<String, dynamic>()))
        .toList();
  }

  Future<Map<String, Object?>?> metadata(String resourceId) =>
      store.resourceMetadata(resourceId);
}
