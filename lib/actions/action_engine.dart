import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../auth/auth_service.dart';
import '../data/api/api_client.dart';
import '../data/local/drift_store.dart';
import '../device/capability_bridge.dart';
import '../sync/sync_engine.dart';

class ActionContext {
  const ActionContext({this.data = const {}});

  final Map<String, dynamic> data;
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
    final type = '${action['type'] ?? action['action'] ?? ''}';
    switch (type) {
      case 'navigate':
        final route = action['route'] ?? action['target'];
        if (route is String && route.isNotEmpty) {
          return Navigator.of(
            context,
          ).pushNamed(route, arguments: action['params']);
        }
        return null;
      case 'api':
      case 'networkRequest':
        return api.request(
          method: '${action['method'] ?? 'GET'}',
          path: '${action['url'] ?? '/'}',
          query: (action['query'] as Map?)?.cast<String, dynamic>(),
          headers: (action['headers'] as Map?)?.cast<String, dynamic>(),
          body: action['body'] ?? contextData.data,
        );
      case 'dialog':
      case 'showDialog':
        return showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text('${action['title'] ?? ''}'),
            content: Text('${action['message'] ?? ''}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('إغلاق'),
              ),
            ],
          ),
        );
      case 'snackbar':
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${action['message'] ?? ''}')));
        return null;
      case 'refresh':
      case 'sync':
        return sync.manualSync();
      case 'logout':
        await auth.clear();
        return null;
      case 'open_url':
        final uri = Uri.tryParse('${action['url'] ?? action['target'] ?? ''}');
        if (uri == null) return false;
        return launchUrl(uri, mode: LaunchMode.externalApplication);
      case 'device':
      case 'device_action':
        final capability = action['capability']?.toString();
        if (capability == null || capability.isEmpty) {
          throw ArgumentError('device action requires capability');
        }
        return capabilities.execute(
          context,
          capability,
          (action['args'] as Map?)?.cast<String, dynamic>() ?? const {},
        );
      case 'workflow':
        final steps = (action['steps'] as List?) ?? const [];
        dynamic lastResult;
        for (final step in steps.whereType<Map>()) {
          lastResult = await execute(
            context,
            step.cast<String, dynamic>(),
            contextData: contextData,
          );
        }
        return lastResult;
      default:
        throw UnsupportedError('Unknown runtime action: $type');
    }
  }
}
