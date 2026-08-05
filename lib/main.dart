import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DynamicApp());
}

class AppConfig {
  final String appName;
  final bool loginEnabled;
  final String? homeScreen;
  final int version;
  final String? themeMode;
  final List<DynamicScreen> screens;

  const AppConfig({
    required this.appName,
    required this.loginEnabled,
    required this.homeScreen,
    required this.version,
    required this.themeMode,
    required this.screens,
  });

  factory AppConfig.empty() => const AppConfig(
        appName: 'Dynamic Flutter App',
        loginEnabled: false,
        homeScreen: null,
        version: 0,
        themeMode: 'system',
        screens: [],
      );

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    final screensJson = (json['screens'] as List<dynamic>? ?? const []);
    return AppConfig(
      appName: (json['app_name'] ?? 'Dynamic Flutter App').toString(),
      loginEnabled: json['login_enabled'] == true,
      homeScreen: json['home_screen']?.toString(),
      version: int.tryParse(json['version']?.toString() ?? '0') ?? 0,
      themeMode: json['theme_mode']?.toString(),
      screens: screensJson
          .whereType<Map<String, dynamic>>()
          .map(DynamicScreen.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'app_name': appName,
        'login_enabled': loginEnabled,
        'home_screen': homeScreen,
        'version': version,
        'theme_mode': themeMode,
        'screens': screens.map((e) => e.toJson()).toList(),
      };

  DynamicScreen? screenByName(String? name) {
    if (name == null) return null;
    for (final screen in screens) {
      if (screen.name == name) return screen;
    }
    return null;
  }
}

class DynamicScreen {
  final String name;
  final String title;
  final String? description;
  final List<DynamicComponent> components;

  const DynamicScreen({
    required this.name,
    required this.title,
    required this.components,
    this.description,
  });

  factory DynamicScreen.fromJson(Map<String, dynamic> json) {
    final componentsJson = (json['components'] as List<dynamic>? ?? const []);
    return DynamicScreen(
      name: (json['name'] ?? 'screen').toString(),
      title: (json['title'] ?? 'Screen').toString(),
      description: json['description']?.toString(),
      components: componentsJson
          .whereType<Map<String, dynamic>>()
          .map(DynamicComponent.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'title': title,
        'description': description,
        'components': components.map((e) => e.toJson()).toList(),
      };
}

class DynamicComponent {
  final String type;
  final String? text;
  final String? hint;
  final String? route;
  final String? actionType;
  final String? imageUrl;
  final Map<String, dynamic> extra;

  const DynamicComponent({
    required this.type,
    this.text,
    this.hint,
    this.route,
    this.actionType,
    this.imageUrl,
    this.extra = const {},
  });

  factory DynamicComponent.fromJson(Map<String, dynamic> json) {
    final action = json['action'];
    String? actionType;
    String? route;
    if (action is Map<String, dynamic>) {
      actionType = action['type']?.toString();
      route = action['target']?.toString();
    } else {
      actionType = json['action_type']?.toString();
      route = json['route']?.toString();
    }

    return DynamicComponent(
      type: (json['type'] ?? 'text').toString(),
      text: json['text']?.toString(),
      hint: json['hint']?.toString(),
      route: route,
      actionType: actionType,
      imageUrl: json['image_url']?.toString(),
      extra: json,
    );
  }

  Map<String, dynamic> toJson() => extra;
}

class DynamicApp extends StatefulWidget {
  const DynamicApp({super.key});

  @override
  State<DynamicApp> createState() => _DynamicAppState();
}

class _DynamicAppState extends State<DynamicApp> {
  static const String apiBaseUrl = 'https://flutter.alattab.site';
  static const String configPath = '/api/app-config';
  static const String cacheKey = 'cached_app_config_v1';
  static const String versionKey = 'cached_app_config_version_v1';
  static const String tokenKey = 'cached_auth_token_v1';

  late Future<_BootstrapData> _bootstrapFuture;
  late final ConfigService _configService;

  @override
  void initState() {
    super.initState();
    _configService = ConfigService(
      apiBaseUrl: apiBaseUrl,
      configPath: configPath,
      cacheKey: cacheKey,
      versionKey: versionKey,
      tokenKey: tokenKey,
    );
    _bootstrapFuture = _loadBootstrap();
  }

  Future<_BootstrapData> _loadBootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedJson = prefs.getString(cacheKey);
    AppConfig cachedConfig = AppConfig.empty();

    if (cachedJson != null && cachedJson.trim().isNotEmpty) {
      try {
        cachedConfig = AppConfig.fromJson(
          jsonDecode(cachedJson) as Map<String, dynamic>,
        );
      } catch (_) {
        cachedConfig = AppConfig.empty();
      }
    }

    AppConfig remoteConfig = cachedConfig;
    String? error;

    try {
      final fetched = await _configService.fetchRemoteConfig();
      remoteConfig = fetched;
      await prefs.setString(cacheKey, jsonEncode(remoteConfig.toJson()));
      await prefs.setInt(versionKey, remoteConfig.version);
    } catch (e) {
      error = e.toString();
    }

    return _BootstrapData(
      config: remoteConfig,
      error: error,
    );
  }

  Future<void> _syncNow() async {
    setState(() {
      _bootstrapFuture = _loadBootstrap();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dynamic Flutter App',
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      home: FutureBuilder<_BootstrapData>(
        future: _bootstrapFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _LoadingScreen();
          }

          if (snapshot.hasError) {
            return _ErrorScreen(
              message: snapshot.error.toString(),
              onRetry: _syncNow,
            );
          }

          final data = snapshot.data ?? _BootstrapData(config: AppConfig.empty(), error: null);
          final config = data.config;

          final initialScreen = config.screenByName(config.homeScreen) ??
              (config.screens.isNotEmpty ? config.screens.first : null);

          if (initialScreen == null) {
            return _EmptyConfigScreen(onSync: _syncNow);
          }

          return _ShellScreen(
            appName: config.appName,
            loginEnabled: config.loginEnabled,
            config: config,
            initialScreen: initialScreen,
            onSync: _syncNow,
            bootstrapError: data.error,
            configService: _configService,
          );
        },
      ),
    );
  }
}

class ConfigService {
  final String apiBaseUrl;
  final String configPath;
  final String cacheKey;
  final String versionKey;
  final String tokenKey;

  ConfigService({
    required this.apiBaseUrl,
    required this.configPath,
    required this.cacheKey,
    required this.versionKey,
    required this.tokenKey,
  });

  Future<AppConfig> fetchRemoteConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(tokenKey);

    final uri = Uri.parse('$apiBaseUrl$configPath');
    final headers = <String, String>{
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('Config request failed: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return AppConfig.fromJson(decoded);
    }
    throw Exception('Invalid config format');
  }
}

class _BootstrapData {
  final AppConfig config;
  final String? error;

  const _BootstrapData({required this.config, required this.error});
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('جارِ تحميل الإعدادات...'),
          ],
        ),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorScreen({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48),
              const SizedBox(height: 12),
              const Text('تعذر تحميل الإعدادات'),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.sync),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyConfigScreen extends StatelessWidget {
  final VoidCallback onSync;

  const _EmptyConfigScreen({required this.onSync});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dynamic Flutter App')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.dashboard_customize, size: 56),
              const SizedBox(height: 12),
              const Text('لا توجد شاشات بعد'),
              const SizedBox(height: 8),
              const Text('أضف الشاشات من لوحة Flask ثم اضغط مزامنة.'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onSync,
                icon: const Icon(Icons.sync),
                label: const Text('مزامنة'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShellScreen extends StatefulWidget {
  final String appName;
  final bool loginEnabled;
  final AppConfig config;
  final DynamicScreen initialScreen;
  final VoidCallback onSync;
  final String? bootstrapError;
  final ConfigService configService;

  const _ShellScreen({
    required this.appName,
    required this.loginEnabled,
    required this.config,
    required this.initialScreen,
    required this.onSync,
    required this.bootstrapError,
    required this.configService,
  });

  @override
  State<_ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<_ShellScreen> {
  late DynamicScreen _currentScreen;
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    _currentScreen = widget.initialScreen;
    _loggedIn = !widget.loginEnabled;
  }

  void _navigateTo(String name) {
    final next = widget.config.screenByName(name);
    if (next == null) return;
    setState(() => _currentScreen = next);
  }

  Future<void> _openUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      return;
    }
  }

  Future<void> _handleComponentAction(DynamicComponent component) async {
    final actionType = component.actionType;
    if (actionType == null) return;

    switch (actionType) {
      case 'navigate':
        if (component.route != null) _navigateTo(component.route!);
        break;
      case 'logout':
        setState(() => _loggedIn = false);
        break;
      case 'sync':
        widget.onSync();
        break;
      case 'open_url':
        await _openUrl(component.route);
        break;
      case 'refresh':
        widget.onSync();
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loginEnabled && !_loggedIn) {
      return _LoginScreen(
        appName: widget.appName,
        onLogin: () => setState(() => _loggedIn = true),
        onSync: widget.onSync,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentScreen.title),
        actions: [
          IconButton(
            onPressed: widget.onSync,
            icon: const Icon(Icons.sync),
            tooltip: 'مزامنة',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (widget.bootstrapError != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: Colors.orange.withOpacity(0.15),
                child: Text(
                  'تم استخدام النسخة المحلية بسبب خطأ في المزامنة: ${widget.bootstrapError}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            if (_currentScreen.description != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    _currentScreen.description!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _currentScreen.components.length,
                itemBuilder: (context, index) {
                  final component = _currentScreen.components[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildComponent(context, component),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: widget.onSync,
        icon: const Icon(Icons.sync),
        label: const Text('مزامنة'),
      ),
    );
  }

  Widget _buildComponent(BuildContext context, DynamicComponent component) {
    switch (component.type) {
      case 'text':
        return Text(
          component.text ?? '',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.right,
        );
      case 'title':
        return Text(
          component.text ?? '',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.right,
        );
      case 'button':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _handleComponentAction(component),
            child: Text(component.text ?? 'زر'),
          ),
        );
      case 'outlined_button':
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => _handleComponentAction(component),
            child: Text(component.text ?? 'زر'),
          ),
        );
      case 'card_button':
        return Card(
          child: ListTile(
            title: Text(component.text ?? 'عنصر', textAlign: TextAlign.right),
            subtitle: component.hint != null ? Text(component.hint!) : null,
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _handleComponentAction(component),
          ),
        );
      case 'input':
        return TextField(
          decoration: InputDecoration(
            labelText: component.text ?? 'حقل',
            hintText: component.hint,
            border: const OutlineInputBorder(),
          ),
        );
      case 'divider':
        return const Divider();
      case 'spacer':
        return SizedBox(height: int.tryParse(component.hint ?? '16')?.toDouble() ?? 16);
      case 'image':
        if (component.imageUrl == null || component.imageUrl!.isEmpty) {
          return const SizedBox.shrink();
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            component.imageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Text('تعذر تحميل الصورة'),
            ),
          ),
        );
      default:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text('نوع غير مدعوم: ${component.type}'),
        );
    }
  }
}

class _LoginScreen extends StatelessWidget {
  final String appName;
  final VoidCallback onLogin;
  final VoidCallback onSync;

  const _LoginScreen({
    required this.appName,
    required this.onLogin,
    required this.onSync,
  });

  @override
  Widget build(BuildContext context) {
    final userController = TextEditingController();
    final passController = TextEditingController();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline, size: 56),
                  const SizedBox(height: 12),
                  Text(appName, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 24),
                  TextField(
                    controller: userController,
                    decoration: const InputDecoration(
                      labelText: 'اسم المستخدم',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'كلمة المرور',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onLogin,
                      child: const Text('تسجيل الدخول'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: onSync,
                    icon: const Icon(Icons.sync),
                    label: const Text('مزامنة'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
