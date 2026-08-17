class PermissionService {
  PermissionService({Map<String, dynamic>? grants})
    : _grants = grants ?? const {};

  final Map<String, dynamic> _grants;

  bool can(String permission) =>
      _grants[permission] == true ||
      (_grants['permissions'] is List &&
          (_grants['permissions'] as List).contains(permission));

  bool featureEnabled(String feature) {
    final flags = _grants['feature_flags'];
    return flags is Map<String, dynamic> && flags[feature] == true;
  }
}
