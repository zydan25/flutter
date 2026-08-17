import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stac/stac.dart';

import '../actions/action_engine.dart';
import '../data/local/drift_store.dart';
import '../events/event_engine.dart';
import '../runtime/resource_binding.dart';
import '../runtime/runtime_action_parser.dart';
import '../settings/settings_screen.dart';

class ServerDrivenApp extends StatefulWidget {
  const ServerDrivenApp({
    super.key,
    required this.manifest,
    required this.store,
    required this.actionEngine,
    required this.eventEngine,
    required this.sync,
  });

  final Map<String, dynamic> manifest;
  final DriftStore store;
  final ActionEngine actionEngine;
  final EventEngine eventEngine;
  final dynamic sync;

  @override
  State<ServerDrivenApp> createState() => _ServerDrivenAppState();
}

class _ServerDrivenAppState extends State<ServerDrivenApp> {
  final ResourceBindingEngine _bindings = const ResourceBindingEngine();
  StreamSubscription? _events;
  Map<String, dynamic> _resources = const {};

  @override
  void initState() {
    super.initState();
    _loadResources();
    _events = widget.eventEngine.events.listen((event) {
      switch (event.type) {
        case 'force_logout':
          widget.actionEngine.auth.clear();
          break;
        case 'notification':
        case 'permission.changed':
        case 'feature_flag.changed':
        case 'config.updated':
        case 'entity.updated':
        case 'entity.deleted':
          // Realtime routing remains independent of manual full synchronization.
          break;
      }
    });
  }

  Future<void> _loadResources() async {
    final resources = await widget.store.allResources();
    if (mounted) setState(() => _resources = resources);
  }

  @override
  void dispose() {
    _events?.cancel();
    unawaited(widget.eventEngine.dispose());
    super.dispose();
  }

  ThemeData _theme() {
    final theme = widget.manifest['theme'];
    var scheme = ColorScheme.fromSeed(seedColor: Colors.indigo);
    if (theme is Map<String, dynamic>) {
      final primary = theme['primary']?.toString();
      if (primary != null && primary.startsWith('#')) {
        final value = int.tryParse(primary.substring(1), radix: 16);
        if (value != null) {
          scheme = ColorScheme.fromSeed(seedColor: Color(0xFF000000 | value));
        }
      }
    }
    return ThemeData(useMaterial3: true, colorScheme: scheme);
  }

  List<Map<String, dynamic>> _screens() =>
      (widget.manifest['screens'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList();

  Map<String, dynamic>? _findScreen(String name) {
    for (final screen in _screens()) {
      if ('${screen['name']}' == name) {
        return screen;
      }
    }
    return null;
  }

  Map<String, dynamic> _toStac(Map<String, dynamic> screen) {
    final direct = screen['stac'];
    final tree = direct is Map<String, dynamic>
        ? direct
        : {
            'type': 'scaffold',
            'appBar': {
              'type': 'appBar',
              'title': {
                'type': 'text',
                'data': '${screen['title'] ?? 'Screen'}',
              },
            },
            'body': {
              'type': 'singleChildScrollView',
              'child': {
                'type': 'padding',
                'padding': {
                  'left': 16,
                  'right': 16,
                  'top': 16,
                  'bottom': 32,
                },
                'child': {
                  'type': 'column',
                  'children': [
                    ...screen['description'] == null
                        ? const <Map<String, dynamic>>[]
                        : <Map<String, dynamic>>[
                            {
                              'type': 'text',
                              'data': '${screen['description']}',
                            },
                          ],
                    ...((screen['components'] as List? ?? const [])
                        .whereType<Map<String, dynamic>>()
                        .map(_legacyComponent)),
                  ],
                },
              },
            },
          };
    return (_bindings.bind(tree, _resources) as Map).cast<String, dynamic>();
  }

  Map<String, dynamic> _legacyComponent(Map<String, dynamic> component) {
    final type = '${component['type'] ?? 'text'}';
    final text = '${component['text'] ?? ''}';
    final action = component['action'];
    final stacAction = action is Map<String, dynamic>
        ? {'type': 'runtime_action', 'action': action}
        : null;
    switch (type) {
      case 'title':
        return {
          'type': 'text',
          'data': text,
          'style': {'fontSize': 24, 'fontWeight': 'bold'},
        };
      case 'button':
        return {
          'type': 'elevatedButton',
          'child': {'type': 'text', 'data': text},
          ...stacAction == null ? const {} : {'onPressed': stacAction},
        };
      case 'outlined_button':
        return {
          'type': 'outlinedButton',
          'child': {'type': 'text', 'data': text},
          ...stacAction == null ? const {} : {'onPressed': stacAction},
        };
      case 'input':
        return {
          'type': 'textField',
          'decoration': {
            'labelText': text,
            'hintText': component['hint']?.toString(),
          },
        };
      case 'divider':
        return {'type': 'divider'};
      case 'spacer':
        return {
          'type': 'sizedBox',
          'height': double.tryParse('${component['height'] ?? 16}') ?? 16,
        };
      case 'image':
        return {
          'type': 'image',
          'url': '${component['image_url'] ?? ''}',
          'fit': 'cover',
        };
      default:
        return {'type': 'text', 'data': text.isEmpty ? type : text};
    }
  }

  @override
  Widget build(BuildContext context) {
    final home = '${widget.manifest['home_screen'] ?? ''}';
    final initial = home.isNotEmpty
        ? home
        : (_screens().isNotEmpty ? '${_screens().first['name']}' : '');

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '${widget.manifest['app_name'] ?? 'Server Driven App'}',
      theme: _theme(),
      home: initial.isEmpty
          ? const Scaffold(body: Center(child: Text('لا توجد شاشة')))
          : Builder(
              builder: (context) {
                final screen = _findScreen(initial);
                if (screen == null) {
                  return const Scaffold(
                    body: Center(child: Text('Screen not found')),
                  );
                }
                return Stac.fromJson(_toStac(screen), context) ??
                    const SizedBox.shrink();
              },
            ),
      onGenerateRoute: (settings) {
        final name = settings.name ?? '/';
        if (name == '/settings') {
          return MaterialPageRoute(
            builder: (_) =>
                SettingsScreen(store: widget.store, sync: widget.sync),
          );
        }
        final screen =
            _findScreen(name.replaceFirst('/', '')) ?? _findScreen(name);
        if (screen == null) {
          return MaterialPageRoute(
            builder: (_) =>
                const Scaffold(body: Center(child: Text('Route not found'))),
          );
        }
        return MaterialPageRoute(
          builder: (context) =>
              Stac.fromJson(_toStac(screen), context) ??
              const SizedBox.shrink(),
        );
      },
    );
  }
}

Future<void> initializeStac(ActionEngine engine) =>
    Stac.initialize(actionParsers: [RuntimeActionParser(engine)]);
