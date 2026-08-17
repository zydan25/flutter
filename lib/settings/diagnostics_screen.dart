import 'package:flutter/material.dart';

import '../data/local/drift_store.dart';
import 'diagnostics_service.dart';

class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({super.key, required this.store});
  final DriftStore store;

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  late final DiagnosticsService _service;
  Future<Map<String, String>>? _snapshot;
  Future<List<DiagnosticCheck>>? _selfTest;

  @override
  void initState() {
    super.initState();
    _service = DiagnosticsService(widget.store);
    _reload();
  }

  void _reload() {
    _snapshot = _service.snapshot();
    _selfTest = _service.selfTest();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تشخيص Runtime'),
        actions: [
          IconButton(
            tooltip: 'إعادة الفحص',
            onPressed: () => setState(_reload),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        children: [
          FutureBuilder<Map<String, String>>(
            future: _snapshot,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return Column(
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
          const Divider(),
          const ListTile(
            leading: Icon(Icons.health_and_safety_outlined),
            title: Text('اختبار سلامة Runtime'),
          ),
          FutureBuilder<List<DiagnosticCheck>>(
            future: _selfTest,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return Column(
                children: snapshot.data!
                    .map(
                      (check) => ListTile(
                        leading: Icon(
                          check.ok ? Icons.check_circle : Icons.error,
                        ),
                        title: Text(check.name),
                        subtitle: check.message == null
                            ? null
                            : Text(check.message!),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
