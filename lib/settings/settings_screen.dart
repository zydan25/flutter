import 'package:flutter/material.dart';

import '../data/local/drift_store.dart';
import '../sync/sync_engine.dart';
import 'diagnostics_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.store, required this.sync});
  final DriftStore store;
  final SyncEngine sync;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _busy = false;
  String? _lastSync;
  int _pending = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final values = await Future.wait<dynamic>([
      widget.store.meta('last_sync'),
      widget.store.pendingCount(),
    ]);
    if (!mounted) return;
    setState(() {
      _lastSync = values[0] as String?;
      _pending = values[1] as int;
    });
  }

  Future<void> _sync() async {
    setState(() => _busy = true);
    try {
      await widget.sync.manualSync();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت المزامنة بنجاح')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشلت المزامنة: $error')),
        );
      }
    } finally {
      if (mounted) {
        await _load();
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        children: [
          const ListTile(
            title: Text('الحساب'),
            leading: Icon(Icons.person_outline),
          ),
          const ListTile(
            title: Text('الأمان'),
            leading: Icon(Icons.security_outlined),
          ),
          const ListTile(
            title: Text('الإشعارات'),
            leading: Icon(Icons.notifications_outlined),
          ),
          const ListTile(
            title: Text('المظهر'),
            leading: Icon(Icons.palette_outlined),
          ),
          const ListTile(
            title: Text('التخزين'),
            leading: Icon(Icons.storage_outlined),
          ),
          const Divider(),
          ListTile(
            title: const Text('آخر مزامنة'),
            subtitle: Text(_lastSync ?? 'لا توجد'),
          ),
          ListTile(
            title: const Text('العناصر المعلقة'),
            subtitle: Text('$_pending'),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: _busy ? null : _sync,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
              label: const Text('مزامنة الآن'),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.monitor_heart_outlined),
            title: const Text('التشخيص'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DiagnosticsScreen(store: widget.store),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
