import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../auth/auth_service.dart';
import '../data/api/api_client.dart';
import '../data/api/transfer_service.dart';
import '../data/local/drift_store.dart';
import '../device/capability_bridge.dart';
import '../permissions/permission_service.dart';
import '../sync/sync_engine.dart';
import 'action_template.dart';
import 'action_transaction.dart';

class ActionContext {
  const ActionContext({this.data = const {}});

  final Map<String, dynamic> data;

  ActionContext merge(Map<String, dynamic> extra) =>
      ActionContext(data: {...data, ...extra});
}

class ActionEngine {
  ActionEngine({
    required this.api,
    required this.store,
    required this.sync,
    required this.auth,
    required this.capabilities,
    PermissionService? permissions,
    TransferService? transfer,
  })  : permissions = permissions ?? PermissionService(),
        transfer = transfer ?? TransferService(api);

  final ApiClient api;
  final DriftStore store;
  final SyncEngine sync;
  final AuthService auth;
  final CapabilityBridge capabilities;
  final PermissionService permissions;
  final TransferService transfer;

  Future<String?> _resolveApiBaseUrl(Map<String, dynamic> action) async {
    final explicit = action['base_url']?.toString().trim();
    if (explicit != null && explicit.isNotEmpty) return explicit;

    final manifest = await store.resource('runtime_manifest');
    if (manifest == null) return null;
    final apiConfig = manifest['api'];
    if (apiConfig is! Map) return null;

    final profileSlug = action['api_profile']?.toString();
    final profiles = apiConfig['profiles'];
    if (profileSlug != null && profiles is List) {
      for (final raw in profiles) {
        if (raw is Map && '${raw['slug']}' == profileSlug) {
          final base = raw['base_url']?.toString().trim();
          if (base != null && base.isNotEmpty) return base;
        }
      }
    }

    final defaultProfile = apiConfig['default_profile'];
    if (defaultProfile is Map) {
      final base = defaultProfile['base_url']?.toString().trim();
      if (base != null && base.isNotEmpty) return base;
    }
    return null;
  }

  String _resolvePath(String path, String? baseUrl) {
    final uri = Uri.tryParse(path);
    if (uri != null && uri.hasScheme) return path;
    if (baseUrl == null || baseUrl.isEmpty) return path;
    return Uri.parse('${baseUrl.replaceFirst(RegExp(r'/+$'), '')}/')
        .resolve(path.replaceFirst(RegExp(r'^/+'), ''))
        .toString();
  }

  Future<dynamic> execute(
    BuildContext context,
    Map<String, dynamic> action, {
    ActionContext contextData = const ActionContext(),
  }) async {
    final resolved = (ActionTemplate.resolve(action, contextData.data) as Map)
        .cast<String, dynamic>();
    if (!permissions.canExecuteAction(resolved)) {
      throw StateError('Permission denied for runtime action');
    }

    final type = '${resolved['type'] ?? resolved['action'] ?? ''}';

    switch (type) {
      case 'navigate':
        final route = resolved['route'] ?? resolved['target'];
        if (route is String && route.isNotEmpty) {
          return Navigator.of(
            context,
          ).pushNamed(route, arguments: resolved['params']);
        }
        return null;
      case 'api':
      case 'networkRequest':
        final baseUrl = await _resolveApiBaseUrl(resolved);
        return api.request(
          method: '${resolved['method'] ?? 'GET'}',
          path: _resolvePath('${resolved['url'] ?? '/'}', baseUrl),
          query: (resolved['query'] as Map?)?.cast<String, dynamic>(),
          pathParameters: (resolved['path'] as Map?)?.cast<String, dynamic>(),
          headers: (resolved['headers'] as Map?)?.cast<String, dynamic>(),
          body: resolved['body'] ?? contextData.data,
        );
      case 'upload':
        final filePath = resolved['file_path']?.toString();
        final path = resolved['url']?.toString();
        if (filePath == null || filePath.isEmpty || path == null || path.isEmpty) {
          throw ArgumentError('upload action requires file_path and url');
        }
        final baseUrl = await _resolveApiBaseUrl(resolved);
        return transfer.upload(
          path: _resolvePath(path, baseUrl),
          filePath: filePath,
          field: resolved['field']?.toString() ?? 'file',
          fields: (resolved['fields'] as Map?)?.cast<String, dynamic>(),
        );
      case 'download':
        final path = resolved['url']?.toString();
        if (path == null || path.isEmpty) {
          throw ArgumentError('download action requires url');
        }
        final baseUrl = await _resolveApiBaseUrl(resolved);
        return transfer.download(
          path: _resolvePath(path, baseUrl),
          fileName: resolved['file_name']?.toString(),
        );
      case 'dialog':
      case 'showDialog':
        return showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text('${resolved['title'] ?? ''}'),
            content: Text('${resolved['message'] ?? ''}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('إغلاق'),
              ),
            ],
          ),
        );
      case 'snackbar':
      case 'showSnackBar':
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${resolved['message'] ?? ''}')));
        return null;
      case 'refresh':
      case 'sync':
        return sync.manualSync();
      case 'logout':
        await auth.clear();
        return null;
      case 'open_url':
      case 'openUrl':
        final uri = Uri.tryParse(
          '${resolved['url'] ?? resolved['target'] ?? ''}',
        );
        if (uri == null) return false;
        return launchUrl(uri, mode: LaunchMode.externalApplication);
      case 'device':
      case 'device_action':
        final capability = resolved['capability']?.toString();
        if (capability == null || capability.isEmpty) {
          throw ArgumentError('device action requires capability');
        }
        return capabilities.execute(
          context,
          capability,
          (resolved['args'] as Map?)?.cast<String, dynamic>() ?? const {},
        );
      case 'set_state':
        final key = resolved['key']?.toString();
        if (key == null || key.isEmpty) {
          return resolved['value'];
        }
        final transaction = ActionTransaction(store);
        try {
          await transaction.setMeta(key, '${resolved['value'] ?? ''}');
          transaction.commit();
          return resolved['value'];
        } catch (_) {
          await transaction.rollback();
          rethrow;
        }
      case 'workflow':
        return _workflow(context, resolved, contextData);
      default:
        throw UnsupportedError('Unknown runtime action: $type');
    }
  }

  Future<dynamic> _workflow(
    BuildContext context,
    Map<String, dynamic> workflow,
    ActionContext initial,
  ) async {
    var current = initial;
    final seed = workflow['context'];
    if (seed is Map) current = current.merge(seed.cast<String, dynamic>());

    final transaction = ActionTransaction(store);
    dynamic result;
    final steps = (workflow['steps'] as List?) ?? const [];
    try {
      for (final raw in steps.whereType<Map>()) {
        final step = raw.cast<String, dynamic>();
        if (!_passes(step['when'], current.data)) continue;
        result = await execute(context, step, contextData: current);
        if (!context.mounted) {
          await transaction.rollback();
          return result;
        }
        final saveAs = step['save_as'];
        if (saveAs is String && saveAs.isNotEmpty) {
          current = current.merge({saveAs: result});
        }
      }
      transaction.commit();
      return result;
    } catch (error) {
      await transaction.rollback();
      if (!context.mounted) rethrow;
      final fallback = workflow['on_error'];
      if (fallback is Map) {
        return execute(
          context,
          fallback.cast<String, dynamic>(),
          contextData: current.merge({'error': '$error'}),
        );
      }
      rethrow;
    }
  }

  bool _passes(dynamic condition, Map<String, dynamic> data) {
    if (condition == null) return true;
    if (condition is bool) return condition;
    if (condition is! Map) return true;
    final left = ActionTemplate.resolve(condition['value'], data);
    final right = ActionTemplate.resolve(condition['equals'], data);
    switch ('${condition['operator'] ?? 'equals'}') {
      case 'equals':
      case '==':
        return left == right;
      case 'not_equals':
      case '!=':
        return left != right;
      case 'exists':
        return left != null;
      case 'not_exists':
        return left == null;
      case 'truthy':
        return left == true || (left is String && left.isNotEmpty);
      default:
        return true;
    }
  }
}
