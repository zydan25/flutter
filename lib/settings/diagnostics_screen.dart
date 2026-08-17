import 'package:flutter/material.dart';

import '../core/runtime_config.dart';
import '../data/local/drift_store.dart';

class DiagnosticsScreen extends StatelessWidget {
  const DiagnosticsScreen({super.key, required this.store});
  final DriftStore store;

  Future<Map<String, String>> _snapshot() async {
    return {
      'Runtime version': RuntimeConfig.runtimeVersion,
      'Schema version': RuntimeConfig.schemaVersion,
      'Manifest version': await store.meta('manifest_version') ?? '0',
      'Database version': '1',
      'Last sync': await store.meta('last_sync') ?? 'never',
      'Pending operations': '${await store.pendingCount()}',
      'Cache': (await store.meta('manifest_present')) == '1'
          ? 'ready'
          : 'empty',
      'API': RuntimeConfig.baseUrl,
      'WebSocket': 'independent / event-only',
      'Auth': 'secure-storage session',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تشخيص Runtime')),
      body: FutureBuilder<Map<String, String>>(
        future: _snapshot(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          return ListView(
            children: snapshot.data!.entries
                .map(
                  (entry) => ListTile(
                    title: Text(entry.key),
                    subtitle: Text(entry.value),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}
