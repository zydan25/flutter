import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../auth/auth_service.dart';
import '../data/api/api_client.dart';
import '../data/local/drift_store.dart';
import '../sync/sync_engine.dart';

class ActionContext {
  const ActionContext({this.data = const {}});
  final Map<String, dynamic> data;
}

class ActionEngine {
  ActionEngine({required this.api, required this.store, required this.sync, required this.auth});

  final ApiClient api;
  final DriftStore store;
  final SyncEngine sync;
  final AuthService auth;

  Future<void> execute(BuildContext context, Map<String, dynamic> action, {ActionContext contextData = const ActionContext()}) async {
    final type = '${action['type'] ?? action['action'] ?? ''}';
    switch (type) {
      case 'navigate':
        final route = action['route'] ?? action['target'];
        if (route is String) {
          Navigator.of(context).pushNamed(route, arguments: action['params']);
        }
        return;
      case 'api':
      case 'networkRequest':
        await api.request(
          method: '${action['method'] ?? 'GET'}',
          path: '${action['url'] ?? '/'}',
          query: (action['query'] as Map?)?.cast<String, dynamic>(),
          headers: (action['headers'] as Map?)?.cast<String, dynamic>(),
          body: action['body'] ?? contextData.data,
        );
        return;
      case 'dialog':
      case 'showDialog':
        await showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('${action['title'] ?? ''}'),
            content: Text('${action['message'] ?? ''}'),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق'))],
          ),
        );
        return;
      case 'snackbar':
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${action['message'] ?? ''}')));
        return;
      case 'refresh':
        await sync.manualSync();
        return;
      case 'logout':
        await auth.clear();
        return;
      case 'open_url':
        final uri = Uri.tryParse('${action['url'] ?? action['target'] ?? ''}');
        if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      case 'device':
        throw UnsupportedError('Device capabilities are routed through CapabilityBridge');
      case 'workflow':
        final steps = (action['steps'] as List?) ?? const [];
        for (final step in steps.whereType<Map>()) {
          await execute(context, step.cast<String, dynamic>(), contextData: contextData);
        }
        return;
      default:
        throw UnsupportedError('Unknown runtime action: $type');
    }
  }
}
