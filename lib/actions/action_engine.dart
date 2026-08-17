import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../auth/auth_service.dart';
import '../data/api/api_client.dart';
import '../data/local/drift_store.dart';
import '../device/capability_bridge.dart';
import '../sync/sync_engine.dart';
import 'action_template.dart';

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
  });

  final ApiClient api;
  final DriftStore store;
  final SyncEngine sync;
  final AuthService auth;
  final CapabilityBridge capabilities;

  Future<dynamic> execute(
    BuildContext context,
    Map<String, dynamic> action, {
    ActionContext contextData = const ActionContext(),
  }) async {
    final resolved = (ActionTemplate.resolve(action, contextData.data) as Map)
        .cast<String, dynamic>();
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
        return api.request(
          method: '${resolved['method'] ?? 'GET'}',
          path: '${resolved['url'] ?? '/'}',
          query: (resolved['query'] as Map?)?.cast<String, dynamic>(),
          headers: (resolved['headers'] as Map?)?.cast<String, dynamic>(),
          body: resolved['body'] ?? contextData.data,
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
        return resolved['value'];
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

    dynamic result;
    final steps = (workflow['steps'] as List?) ?? const [];
    for (final raw in steps.whereType<Map>()) {
      final step = raw.cast<String, dynamic>();
      if (!_passes(step['when'], current.data)) continue;
      try {
        result = await execute(context, step, contextData: current);
        if (!context.mounted) return result;
        final saveAs = step['save_as'];
        if (saveAs is String && saveAs.isNotEmpty) {
          current = current.merge({saveAs: result});
        }
      } catch (error) {
        if (!context.mounted) rethrow;
        final fallback = step['on_error'];
        if (fallback is Map) {
          result = await execute(
            context,
            fallback.cast<String, dynamic>(),
            contextData: current.merge({'error': '$error'}),
          );
        } else {
          rethrow;
        }
      }
    }
    return result;
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
