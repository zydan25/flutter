import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stac/stac.dart';

/// First STAC-backed Runtime bridge.
///
/// The existing Flask contract is intentionally kept compatible: the server
/// continues returning `app_config`, while this adapter translates the
/// existing screen/component model into STAC JSON at the Runtime boundary.
class StacRuntimeApp extends StatefulWidget {
  const StacRuntimeApp({super.key});

  @override
  State<StacRuntimeApp> createState() => _StacRuntimeAppState();
}

class _StacRuntimeAppState extends State<StacRuntimeApp> {
  static const _endpoint = 'https://flutter.alattab.site/api/app-config';
  static const _cacheKey = 'stac_runtime_app_config_v1';

  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadConfig();
  }

  Future<Map<String, dynamic>> _loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey);

    try {
      final response = await http
          .get(Uri.parse(_endpoint), headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('Runtime bootstrap failed: ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Invalid runtime manifest');
      }

      await prefs.setString(_cacheKey, jsonEncode(decoded));
      return decoded;
    } catch (_) {
      if (cached == null || cached.isEmpty) rethrow;
      final decoded = jsonDecode(cached);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Invalid cached runtime manifest');
      }
      return decoded;
    }
  }

  void _retry() {
    setState(() => _future = _loadConfig());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasError) {
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off, size: 52),
                      const SizedBox(height: 12),
                      const Text('تعذر تحميل التطبيق'),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _retry,
                        icon: const Icon(Icons.refresh),
                        label: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        final config = snapshot.data!;
        return _StacHost(config: config);
      },
    );
  }
}

class _StacHost extends StatelessWidget {
  final Map<String, dynamic> config;

  const _StacHost({required this.config});

  @override
  Widget build(BuildContext context) {
    final appName = (config['app_name'] ?? 'Dynamic Flutter App').toString();
    final homeName = (config['home_screen'] ?? '').toString();
    final screens = (config['screens'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();

    final home = screens.firstWhere(
      (screen) => screen['name']?.toString() == homeName,
      orElse: () => screens.isNotEmpty ? screens.first : <String, dynamic>{},
    );

    if (home.isEmpty) {
      return MaterialApp(
        title: appName,
        home: const Scaffold(
          body: Center(child: Text('لا توجد شاشة رئيسية في Runtime Manifest')),
        ),
      );
    }

    final stacJson = _screenToStac(home, screens);

    return StacApp(
      title: appName,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      homeBuilder: (context) => Stac.fromJson(stacJson, context),
    );
  }

  Map<String, dynamic> _screenToStac(
    Map<String, dynamic> screen,
    List<Map<String, dynamic>> screens,
  ) {
    final components = (screen['components'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(_componentToStac)
        .toList();

    return {
      'type': 'scaffold',
      'appBar': {
        'type': 'appBar',
        'title': {
          'type': 'text',
          'data': (screen['title'] ?? 'Screen').toString(),
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
            'crossAxisAlignment': 'start',
            'children': [
              if (screen['description'] != null)
                {
                  'type': 'text',
                  'data': screen['description'].toString(),
                },
              ...components,
            ],
          },
        },
      },
    };
  }

  Map<String, dynamic> _componentToStac(Map<String, dynamic> component) {
    final type = (component['type'] ?? 'text').toString();
    final text = (component['text'] ?? '').toString();

    switch (type) {
      case 'title':
        return {
          'type': 'text',
          'data': text,
          'style': {'fontSize': 24, 'fontWeight': 'bold'},
        };
      case 'button':
      case 'outlined_button':
      case 'card_button':
        return {
          'type': type == 'outlined_button'
              ? 'outlinedButton'
              : 'elevatedButton',
          'child': {'type': 'text', 'data': text},
          'onPressed': <String, dynamic>{},
        };
      case 'divider':
        return {'type': 'divider'};
      case 'spacer':
        return {
          'type': 'sizedBox',
          'height': double.tryParse(component['height']?.toString() ?? '') ?? 16,
        };
      case 'image':
        final url = component['image_url']?.toString();
        if (url == null || url.isEmpty) {
          return {'type': 'sizedBox', 'height': 1};
        }
        return {
          'type': 'image',
          'url': url,
          'fit': 'cover',
        };
      case 'input':
        return {
          'type': 'textField',
          'decoration': {
            'hintText': component['hint']?.toString(),
          },
        };
      default:
        return {
          'type': 'text',
          'data': text.isEmpty ? type : text,
        };
    }
  }
}
