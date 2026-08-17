class PermissionService {
  PermissionService({Map<String, dynamic>? grants}) : _grants = grants ?? const {};

  Map<String, dynamic> _grants;

  bool can(String permission) =>
      _grants[permission] == true ||
      (_grants['permissions'] is List &&
          (_grants['permissions'] as List).contains(permission));

  bool featureEnabled(String feature) {
    final flags = _grants['feature_flags'];
    return flags is Map<String, dynamic> && flags[feature] == true;
  }

  void update(Map<String, dynamic> grants) {
    _grants = grants;
  }

  Map<String, dynamic> get grants => Map<String, dynamic>.unmodifiable(_grants);

  bool canNavigate(Map<String, dynamic> route) {
    final permission = route['permission']?.toString();
    if (permission == null || permission.isEmpty) return true;
    return can(permission);
  }

  bool canExecuteAction(Map<String, dynamic> action) {
    final permission = action['permission']?.toString();
    if (permission == null || permission.isEmpty) return true;
    return can(permission);
  }
}
