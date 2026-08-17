import '../core/runtime_config.dart';
import '../data/local/drift_store.dart';

class DiagnosticCheck {
  const DiagnosticCheck({required this.name, required this.ok, this.message});

  final String name;
  final bool ok;
  final String? message;
}

class DiagnosticsService {
  DiagnosticsService(this.store);

  final DriftStore store;

  Future<List<DiagnosticCheck>> selfTest() async {
    final checks = <DiagnosticCheck>[];
    try {
      await store.setMeta('diagnostic_probe', DateTime.now().toUtc().toIso8601String());
      checks.add(const DiagnosticCheck(name: 'SQLite', ok: true));
    } catch (error) {
      checks.add(DiagnosticCheck(name: 'SQLite', ok: false, message: '$error'));
    }

    try {
      final resources = await store.allResources();
      checks.add(
        DiagnosticCheck(
          name: 'Local resources',
          ok: true,
          message: '${resources.length} resources',
        ),
      );
    } catch (error) {
      checks.add(DiagnosticCheck(name: 'Local resources', ok: false, message: '$error'));
    }

    final base = RuntimeConfig.baseUrl;
    checks.add(
      DiagnosticCheck(
        name: 'API configuration',
        ok: base.startsWith('https://') || base.startsWith('http://'),
        message: base,
      ),
    );
    return checks;
  }

  Future<Map<String, String>> snapshot() async {
    return {
      'Runtime version': RuntimeConfig.runtimeVersion,
      'Schema version': RuntimeConfig.schemaVersion,
      'Manifest version': await store.meta('manifest_version') ?? '0',
      'Database version': '1',
      'Last sync': await store.meta('last_sync') ?? 'never',
      'Pending operations': '${await store.pendingCount()}',
      'Pending conflicts': '${await store.pendingConflictCount()}',
      'Cache': await store.meta('manifest_present') == '1' ? 'ready' : 'empty',
      'API': RuntimeConfig.baseUrl,
      'WebSocket': 'event-only / independent from full sync',
      'Auth': 'secure-storage session',
    };
  }
}
