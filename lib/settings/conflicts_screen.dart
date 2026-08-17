import 'dart:convert';

import 'package:flutter/material.dart';

import '../data/local/drift_store.dart';

class ConflictsScreen extends StatefulWidget {
  const ConflictsScreen({super.key, required this.store});

  final DriftStore store;

  @override
  State<ConflictsScreen> createState() => _ConflictsScreenState();
}

class _ConflictsScreenState extends State<ConflictsScreen> {
  List<Map<String, Object?>> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await widget.store.conflicts();
    if (mounted) setState(() => _items = items);
  }

  Future<void> _resolve(String operationId, String resolution) async {
    await widget.store.resolveConflict(
      operationId: operationId,
      resolution: resolution,
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تعارضات المزامنة')),
      body: _items.isEmpty
          ? const Center(child: Text('لا توجد تعارضات معلقة'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                final operationId = '${item['operation_id']}';
                final local = _decode(item['local_payload']);
                final server = _decode(item['server_payload']);
                return Card(
                  child: ExpansionTile(
                    title: Text('${item['entity']} / $operationId'),
                    subtitle: Text(
                      'الإصدار المحلي: ${item['base_version'] ?? '-'} • الخادم: ${item['server_version'] ?? '-'}',
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text('المحلي: ${jsonEncode(local)}'),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text('الخادم: ${jsonEncode(server)}'),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          OutlinedButton(
                            onPressed: () => _resolve(operationId, 'server_wins'),
                            child: const Text('اعتماد الخادم'),
                          ),
                          OutlinedButton(
                            onPressed: () => _resolve(operationId, 'client_wins'),
                            child: const Text('اعتماد المحلي'),
                          ),
                          FilledButton.tonal(
                            onPressed: () => _resolve(operationId, 'manual'),
                            child: const Text('حل يدوي'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Map<String, dynamic> _decode(Object? value) {
    if (value is String && value.isNotEmpty) {
      final decoded = jsonDecode(value);
      if (decoded is Map<String, dynamic>) return decoded;
    }
    return const {};
  }
}
