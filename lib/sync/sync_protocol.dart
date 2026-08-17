enum SyncOperationStatus { acknowledged, conflict, rejected, retry, pending }

class SyncOperationResult {
  const SyncOperationResult({
    required this.operationId,
    required this.status,
    this.serverVersion,
    this.serverData,
    this.conflictData,
    this.message,
  });

  final String operationId;
  final SyncOperationStatus status;
  final int? serverVersion;
  final Map<String, dynamic>? serverData;
  final Map<String, dynamic>? conflictData;
  final String? message;

  factory SyncOperationResult.fromJson(Map<String, dynamic> json) {
    final rawStatus = '${json['status'] ?? 'pending'}'.toLowerCase();
    final status = switch (rawStatus) {
      'acknowledged' || 'ok' || 'accepted' => SyncOperationStatus.acknowledged,
      'conflict' => SyncOperationStatus.conflict,
      'rejected' || 'failed' => SyncOperationStatus.rejected,
      'retry' => SyncOperationStatus.retry,
      _ => SyncOperationStatus.pending,
    };
    return SyncOperationResult(
      operationId: '${json['operation_id'] ?? ''}',
      status: status,
      serverVersion: int.tryParse('${json['server_version'] ?? ''}'),
      serverData: (json['server_data'] as Map?)?.cast<String, dynamic>(),
      conflictData: (json['conflict'] as Map?)?.cast<String, dynamic>(),
      message: json['message']?.toString(),
    );
  }
}

class SyncResponse {
  const SyncResponse({required this.operations, this.resources = const []});

  final List<SyncOperationResult> operations;
  final List<Map<String, dynamic>> resources;

  factory SyncResponse.fromJson(Map<String, dynamic> json) {
    final rawOperations = json['operations'];
    final rawResources = json['resources'];
    return SyncResponse(
      operations: rawOperations is List
          ? rawOperations
                .whereType<Map>()
                .map(
                  (item) => SyncOperationResult.fromJson(
                    item.cast<String, dynamic>(),
                  ),
                )
                .toList()
          : const [],
      resources: rawResources is List
          ? rawResources
                .whereType<Map>()
                .map((item) => item.cast<String, dynamic>())
                .toList()
          : const [],
    );
  }
}
