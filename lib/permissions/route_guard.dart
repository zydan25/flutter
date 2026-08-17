import 'permission_service.dart';

class RouteGuard {
  const RouteGuard(this.permissions);

  final PermissionService permissions;

  bool canOpen(Map<String, dynamic> definition) {
    final permission = definition['permission']?.toString();
    if (permission == null || permission.isEmpty) return true;
    return permissions.can(permission);
  }

  bool canFeature(Map<String, dynamic> definition) {
    final feature = definition['feature_flag']?.toString();
    if (feature == null || feature.isEmpty) return true;
    return permissions.featureEnabled(feature);
  }

  bool canExecuteAction(Map<String, dynamic> action) {
    final permission = action['permission']?.toString();
    if (permission != null && permission.isNotEmpty && !permissions.can(permission)) {
      return false;
    }
    final feature = action['feature_flag']?.toString();
    if (feature != null && feature.isNotEmpty && !permissions.featureEnabled(feature)) {
      return false;
    }
    return true;
  }
}
