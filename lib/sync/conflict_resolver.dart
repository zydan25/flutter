enum ConflictResolution { serverWins, clientWins, merge, manual }

class SyncConflict {
  const SyncConflict({
    required this.operationId,
    required this.entity,
    required this.entityId,
    required this.serverVersion,
    required this.clientVersion,
    required this.serverData,
    required this.clientData,
    this.resolution = ConflictResolution.manual,
  });

  final String operationId;
  final String entity;
  final String? entityId;
  final int serverVersion;
  final int clientVersion;
  final Map<String, dynamic> serverData;
  final Map<String, dynamic> clientData;
  final ConflictResolution resolution;
}

class ConflictResolver {
  const ConflictResolver();

  Map<String, dynamic> resolve(SyncConflict conflict) {
    switch (conflict.resolution) {
      case ConflictResolution.serverWins:
        return Map<String, dynamic>.from(conflict.serverData);
      case ConflictResolution.clientWins:
        return Map<String, dynamic>.from(conflict.clientData);
      case ConflictResolution.merge:
        return {...conflict.serverData, ...conflict.clientData};
      case ConflictResolution.manual:
        throw StateError(
          'Manual resolution required for ${conflict.entity}:${conflict.entityId}',
        );
    }
  }
}
