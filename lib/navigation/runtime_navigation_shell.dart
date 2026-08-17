import 'package:flutter/material.dart';

import 'navigation_definition.dart';

class RuntimeNavigationShell extends StatefulWidget {
  const RuntimeNavigationShell({
    super.key,
    required this.navigation,
    required this.initialRoute,
    required this.builder,
    this.canAccess = _allowAll,
  });

  final NavigationDefinition navigation;
  final String initialRoute;
  final Widget Function(BuildContext context, String route) builder;
  final bool Function(String route, String? permission) canAccess;

  static bool _allowAll(String route, String? permission) => true;

  @override
  State<RuntimeNavigationShell> createState() => _RuntimeNavigationShellState();
}

class _RuntimeNavigationShellState extends State<RuntimeNavigationShell> {
  late String _route;

  @override
  void initState() {
    super.initState();
    _route = _normalize(widget.initialRoute);
    if (!_accessible(_route)) {
      final first = [...widget.navigation.bottom, ...widget.navigation.drawer]
          .firstWhere(
            (item) => _accessible(item.route),
            orElse: () => const NavigationItem(route: '', label: ''),
          );
      if (first.route.isNotEmpty) _route = _normalize(first.route);
    }
  }

  String _normalize(String route) => route.startsWith('/') ? route : '/$route';

  bool _accessible(String route) {
    final item = [
      ...widget.navigation.bottom,
      ...widget.navigation.drawer,
      ...widget.navigation.tabs,
    ].where((candidate) => _normalize(candidate.route) == route);
    final candidate = item.isEmpty ? null : item.first;
    return widget.canAccess(route, candidate?.permission);
  }

  void _select(String route) {
    final normalized = _normalize(route);
    if (!_accessible(normalized)) return;
    setState(() => _route = normalized);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = widget.navigation.bottom
        .where((item) => _accessible(_normalize(item.route)))
        .toList();
    final drawer = widget.navigation.drawer
        .where((item) => _accessible(_normalize(item.route)))
        .toList();
    final currentIndex = bottom.indexWhere(
      (item) => _normalize(item.route) == _route,
    );

    return Scaffold(
      drawer: drawer.isEmpty
          ? null
          : Drawer(
              child: SafeArea(
                child: ListView(
                  children: [
                    for (final item in drawer)
                      ListTile(
                        title: Text(item.label),
                        selected: _normalize(item.route) == _route,
                        onTap: () {
                          Navigator.pop(context);
                          _select(item.route);
                        },
                      ),
                  ],
                ),
              ),
            ),
      body: widget.builder(context, _route),
      bottomNavigationBar: bottom.length < 2
          ? null
          : NavigationBar(
              selectedIndex: currentIndex >= 0 ? currentIndex : 0,
              onDestinationSelected: (index) => _select(bottom[index].route),
              destinations: [
                for (final item in bottom)
                  NavigationDestination(
                    icon: const Icon(Icons.circle_outlined),
                    selectedIcon: const Icon(Icons.circle),
                    label: item.label,
                  ),
              ],
            ),
    );
  }
}
