import 'package:flutter/material.dart';
import 'package:stac/stac.dart';

class RuntimeManifest {
  RuntimeManifest(this.raw);

  final Map<String, dynamic> raw;

  String get appName => '${raw['app_name'] ?? 'Server Driven App'}';
  String get homeScreen => '${raw['home_screen'] ?? raw['home_route'] ?? ''}';
  int get version =>
      int.tryParse('${raw['version'] ?? raw['manifest_version'] ?? 0}') ?? 0;
  String? get themeMode => raw['theme_mode']?.toString();

  List<Map<String, dynamic>> get screens =>
      (raw['screens'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList();

  Map<String, dynamic>? screen(String name) {
    for (final item in screens) {
      if ('${item['name']}' == name) {
        return item;
      }
    }
    return null;
  }
}

class StacRuntime extends StatefulWidget {
  const StacRuntime({super.key, required this.manifest});

  final RuntimeManifest manifest;

  @override
  State<StacRuntime> createState() => _StacRuntimeState();
}

class _StacRuntimeState extends State<StacRuntime> {
  late String _screenName;

  @override
  void initState() {
    super.initState();
    _screenName = widget.manifest.homeScreen.isEmpty
        ? (widget.manifest.screens.isNotEmpty
              ? '${widget.manifest.screens.first['name']}'
              : '')
        : widget.manifest.homeScreen;
  }

  Map<String, dynamic> _screenToStac(Map<String, dynamic> screen) {
    final direct = screen['stac'];
    if (direct is Map<String, dynamic>) {
      return direct;
    }
    final components = (screen['components'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(_legacyComponent)
        .toList();
    return {
      'type': 'scaffold',
      'appBar': {
        'type': 'appBar',
        'title': {'type': 'text', 'data': '${screen['title'] ?? 'Screen'}'},
      },
      'body': {
        'type': 'singleChildScrollView',
        'child': {
          'type': 'padding',
          'padding': {'left': 16, 'right': 16, 'top': 16, 'bottom': 32},
          'child': {
            'type': 'column',
            'crossAxisAlignment': 'start',
            'children': [
              ...screen['description'] == null
                  ? const <Map<String, dynamic>>[]
                  : <Map<String, dynamic>>[
                      {'type': 'text', 'data': '${screen['description']}'},
                    ],
              ...components,
            ],
          },
        },
      },
    };
  }

  Map<String, dynamic> _legacyComponent(Map<String, dynamic> component) {
    final type = '${component['type'] ?? 'text'}';
    final text = '${component['text'] ?? ''}';
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
        };
      case 'outlined_button':
        return {
          'type': 'outlinedButton',
          'child': {'type': 'text', 'data': text},
        };
      case 'card_button':
        return {
          'type': 'card',
          'child': {
            'type': 'listTile',
            'title': {'type': 'text', 'data': text},
          },
        };
      case 'input':
        return {
          'type': 'textField',
          'decoration': {
            'hintText': component['hint']?.toString(),
            'labelText': text,
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

  ThemeData _theme() {
    final theme = widget.manifest.raw['theme'];
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

  @override
  Widget build(BuildContext context) {
    final screen = widget.manifest.screen(_screenName);
    if (screen == null) {
      return const Scaffold(body: Center(child: Text('Screen not found')));
    }
    return Theme(
      data: _theme(),
      child:
          Stac.fromJson(_screenToStac(screen), context) ??
          const SizedBox.shrink(),
    );
  }
}
