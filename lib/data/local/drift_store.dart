import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

class DriftStore {
  DriftStore(this.file);

  final File file;
  late final DatabaseConnection connection;

  Future<void> open() async {
    connection = DatabaseConnection(NativeDatabase(file));
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
        created_at TEXT NOT NULL,
        retry_count INTEGER NOT NULL DEFAULT 0,
        next_retry_at TEXT,
        last_error TEXT
      );
    ''');
    await _ensureColumn('sync_queue', 'retry_count', 'INTEGER NOT NULL DEFAULT 0');
    await _ensureColumn('sync_queue', 'next_retry_at', 'TEXT');
    await _ensureColumn('sync_queue', 'last_error', 'TEXT');
    await connection.executor.runCustom('''
      CREATE TABLE IF NOT EXISTS sync_conflicts (
        operation_id TEXT PRIMARY KEY,
        entity TEXT NOT NULL,
        entity_id TEXT,
        base_version INTEGER,
        server_version INTEGER,
        local_payload TEXT NOT NULL,
        server_payload TEXT,
        status TEXT NOT NULL,
        resolution TEXT,
        created_at TEXT NOT NULL,
        resolved_at TEXT
      );
    ''');
  }

  Future<void> _ensureColumn(
    String table,
    String column,
    String definition,
  ) async {
    final rows = await connection.executor.runSelect('PRAGMA table_info($table)');
    final exists = rows.any((row) => row['name'] == column);
    if (!exists) {
      await connection.executor.runCustom(
        'ALTER TABLE $table ADD COLUMN $column $definition',
      );
    }
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

  Future<Map<String, Object?>?> resourceMetadata(String id) async {
    final rows = await connection.executor.runSelect(
      'SELECT resource_id, version, checksum, payload, updated_at FROM resources WHERE resource_id = ?',
      [id],
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<List<Map<String, Object?>>>
  pendingOperations() => connection.executor.runSelect(
    "SELECT * FROM sync_queue WHERE status = 'pending' AND (next_retry_at IS NULL OR next_retry_at <= ?) ORDER BY created_at ASC",
    [DateTime.now().toUtc().toIso8601String()],
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
         (operation_id,entity,entity_id,operation,payload,base_version,status,created_at,retry_count,next_retry_at,last_error)
         VALUES (?,?,?,?,?,?,?,?,?,?,?)''',
      [
        operationId,
        entity,
        entityId,
        operation,
        jsonEncode(payload),
        baseVersion,
        'pending',
        DateTime.now().toUtc().toIso8601String(),
        0,
        null,
        null,
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

  Future<void> scheduleRetry(String id, {
    required int retryCount,
    required DateTime nextRetryAt,
    String? error,
  }) async {
    await connection.executor.runUpdate(
      'UPDATE sync_queue SET status = ?, retry_count = ?, next_retry_at = ?, last_error = ? WHERE operation_id = ?',
      [
        'pending',
        retryCount,
        nextRetryAt.toUtc().toIso8601String(),
        error,
        id,
      ],
    );
  }

  Future<void> saveConflict({
    required String operationId,
    required String entity,
    String? entityId,
    int? baseVersion,
    int? serverVersion,
    required Map<String, dynamic> localPayload,
    Map<String, dynamic>? serverPayload,
  }) async {
    await connection.executor.runCustom(
      '''INSERT OR REPLACE INTO sync_conflicts
      (operation_id,entity,entity_id,base_version,server_version,local_payload,server_payload,status,created_at)
      VALUES (?,?,?,?,?,?,?,?,?)''',
      [
        operationId,
        entity,
        entityId,
        baseVersion,
        serverVersion,
        jsonEncode(localPayload),
        serverPayload == null ? null : jsonEncode(serverPayload),
        'pending',
        DateTime.now().toUtc().toIso8601String(),
      ],
    );
  }

  Future<List<Map<String, Object?>>> conflicts({bool pendingOnly = true}) {
    final where = pendingOnly ? " WHERE status = 'pending'" : '';
    return connection.executor.runSelect(
      'SELECT * FROM sync_conflicts$where ORDER BY created_at DESC',
      const [],
    );
  }

  Future<void> resolveConflict({
    required String operationId,
    required String resolution,
  }) async {
    await connection.executor.runUpdate(
      'UPDATE sync_conflicts SET status = ?, resolution = ?, resolved_at = ? WHERE operation_id = ?',
      [
        'resolved',
        resolution,
        DateTime.now().toUtc().toIso8601String(),
        operationId,
      ],
    );
  }

  Future<int> pendingConflictCount() async {
    final rows = await connection.executor.runSelect(
      "SELECT COUNT(*) AS c FROM sync_conflicts WHERE status = 'pending'",
      const [],
    );
    return (rows.first['c'] as int?) ?? 0;
  }

  Future<void> close() => connection.close();
}
