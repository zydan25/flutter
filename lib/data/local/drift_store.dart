import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

class DriftStore {
  DriftStore(this.file);

  final File file;
  late final DatabaseConnection connection;

  Future<void> open() async {
    connection = DatabaseConnection.fromExecutor(NativeDatabase(file));
    await connection.executor.runCustom('''
      CREATE TABLE IF NOT EXISTS runtime_meta (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      );
    ''');
    await connection.executor.runCustom('''
      CREATE TABLE IF NOT EXISTS resources (
        resource_id TEXT PRIMARY KEY,
        version INTEGER NOT NULL DEFAULT 0,
        checksum TEXT,
        payload TEXT NOT NULL,
        updated_at TEXT
      );
    ''');
    await connection.executor.runCustom('''
      CREATE TABLE IF NOT EXISTS sync_queue (
        operation_id TEXT PRIMARY KEY,
        entity TEXT NOT NULL,
        entity_id TEXT,
        operation TEXT NOT NULL,
        payload TEXT NOT NULL,
        base_version INTEGER,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL
      );
    ''');
  }

  Future<String?> meta(String key) async {
    final rows = await connection.executor.runSelect(
      'SELECT value FROM runtime_meta WHERE key = ?',
      [key],
    );
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }

  Future<void> setMeta(String key, String value) async {
    await connection.executor.runCustom(
      '''INSERT INTO runtime_meta(key,value) VALUES (?,?)
         ON CONFLICT(key) DO UPDATE SET value=excluded.value''',
      [key, value],
    );
  }

  Future<void> saveResource({
    required String id,
    required int version,
    required String checksum,
    required Map<String, dynamic> payload,
    String? updatedAt,
  }) async {
    await connection.executor.runCustom(
      '''INSERT INTO resources(resource_id,version,checksum,payload,updated_at)
         VALUES (?,?,?,?,?)
         ON CONFLICT(resource_id) DO UPDATE SET
           version=excluded.version,
           checksum=excluded.checksum,
           payload=excluded.payload,
           updated_at=excluded.updated_at''',
      [id, version, checksum, jsonEncode(payload), updatedAt],
    );
  }

  Future<Map<String, dynamic>?> resource(String id) async {
    final rows = await connection.executor.runSelect(
      'SELECT payload FROM resources WHERE resource_id = ?',
      [id],
    );
    if (rows.isEmpty) return null;
    final value = rows.first['payload'];
    return jsonDecode(value as String) as Map<String, dynamic>;
  }

  Future<List<Map<String, Object?>>>
  pendingOperations() => connection.executor.runSelect(
    "SELECT * FROM sync_queue WHERE status = 'pending' ORDER BY created_at ASC",
    const [],
  );

  Future<void> enqueue({
    required String operationId,
    required String entity,
    required String operation,
    required Map<String, dynamic> payload,
    String? entityId,
    int? baseVersion,
  }) async {
    await connection.executor.runCustom(
      '''INSERT OR REPLACE INTO sync_queue
         (operation_id,entity,entity_id,operation,payload,base_version,status,created_at)
         VALUES (?,?,?,?,?,?,?,?)''',
      [
        operationId,
        entity,
        entityId,
        operation,
        jsonEncode(payload),
        baseVersion,
        'pending',
        DateTime.now().toUtc().toIso8601String(),
      ],
    );
  }

  Future<int> pendingCount() async {
    final rows = await connection.executor.runSelect(
      "SELECT COUNT(*) AS c FROM sync_queue WHERE status = 'pending'",
      const [],
    );
    return (rows.first['c'] as int?) ?? 0;
  }

  Future<void> markOperation(String id, String status) async {
    await connection.executor.runUpdate(
      'UPDATE sync_queue SET status = ? WHERE operation_id = ?',
      [status, id],
    );
  }

  Future<void> close() => connection.close();
}
