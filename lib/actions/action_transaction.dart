import '../data/local/drift_store.dart';

class ActionTransaction {
  ActionTransaction(this.store);

  final DriftStore store;
  final List<_Undo> _undo = [];
  bool _completed = false;

  Future<void> setMeta(String key, String value) async {
    final previous = await store.meta(key);
    _undo.add(_Undo(() async {
      if (previous == null) {
        await store.setMeta(key, '');
        return;
      }
      await store.setMeta(key, previous);
    }));
    await store.setMeta(key, value);
  }

  Future<void> enqueue({
    required String operationId,
    required String entity,
    required String operation,
    required Map<String, dynamic> payload,
    String? entityId,
    int? baseVersion,
  }) async {
    _undo.add(_Undo(() => store.markOperation(operationId, 'rolled_back')));
    await store.enqueue(
      operationId: operationId,
      entity: entity,
      operation: operation,
      payload: payload,
      entityId: entityId,
      baseVersion: baseVersion,
    );
  }

  void commit() {
    _completed = true;
    _undo.clear();
  }

  Future<void> rollback() async {
    if (_completed) return;
    for (final action in _undo.reversed) {
      await action.run();
    }
    _undo.clear();
  }
}

class _Undo {
  const _Undo(this.run);

  final Future<void> Function() run;
}
