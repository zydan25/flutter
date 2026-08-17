class RuntimeContractException implements Exception {
  const RuntimeContractException(this.message);

  final String message;

  @override
  String toString() => 'RuntimeContractException: $message';
}

class RuntimeContractValidator {
  const RuntimeContractValidator({this.supportedSchemaVersion = 1});

  final int supportedSchemaVersion;

  void validate(Map<String, dynamic> manifest) {
    final schemaVersion = _asInt(manifest['schema_version'] ?? 1);
    if (schemaVersion == null || schemaVersion < 1) {
      throw const RuntimeContractException(
        'schema_version must be a positive integer',
      );
    }
    if (schemaVersion > supportedSchemaVersion) {
      throw RuntimeContractException(
        'Unsupported runtime schema_version=$schemaVersion; '
        'maximum supported=$supportedSchemaVersion',
      );
    }

    final screens = manifest['screens'];
    if (screens != null && screens is! List) {
      throw const RuntimeContractException('screens must be an array');
    }

    if (screens is List) {
      for (final entry in screens) {
        if (entry is! Map) {
          throw const RuntimeContractException(
            'every screen must be an object',
          );
        }
        final screen = entry.cast<String, dynamic>();
        final name = screen['name'];
        final stac = screen['stac'];
        if (name is! String || name.trim().isEmpty) {
          throw const RuntimeContractException(
            'every screen needs a non-empty name',
          );
        }
        if (stac != null && stac is! Map) {
          throw RuntimeContractException('screen $name.stac must be an object');
        }
      }
    }

    final resources = manifest['resources'];
    if (resources != null && resources is! List) {
      throw const RuntimeContractException('resources must be an array');
    }
    if (resources is List) {
      for (final entry in resources) {
        if (entry is! Map) {
          throw const RuntimeContractException(
            'every resource must be an object',
          );
        }
        final resource = entry.cast<String, dynamic>();
        final id = resource['resource_id'] ?? resource['id'];
        if (id is! String || id.trim().isEmpty) {
          throw const RuntimeContractException(
            'every resource needs resource_id',
          );
        }
        final version = _asInt(resource['version'] ?? 0);
        if (version == null || version < 0) {
          throw RuntimeContractException('resource $id has invalid version');
        }
      }
    }
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse('$value');
  }
}
