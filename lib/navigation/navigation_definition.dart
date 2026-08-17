class NavigationItem {
  const NavigationItem({
    required this.route,
    required this.label,
    this.icon,
    this.permission,
  });

  final String route;
  final String label;
  final String? icon;
  final String? permission;

  factory NavigationItem.fromJson(Map<String, dynamic> json) => NavigationItem(
    route: '${json['route'] ?? ''}',
    label: '${json['label'] ?? json['title'] ?? ''}',
    icon: json['icon']?.toString(),
    permission: json['permission']?.toString(),
  );
}

class NavigationDefinition {
  const NavigationDefinition({
    this.drawer = const [],
    this.bottom = const [],
    this.tabs = const [],
    this.deepLinks = const {},
  });

  final List<NavigationItem> drawer;
  final List<NavigationItem> bottom;
  final List<NavigationItem> tabs;
  final Map<String, String> deepLinks;

  factory NavigationDefinition.fromManifest(Map<String, dynamic> manifest) {
    final navigation = manifest['navigation'];
    if (navigation is! Map) return const NavigationDefinition();

    List<NavigationItem> list(dynamic value) => value is List
        ? value
              .whereType<Map>()
              .map((item) => NavigationItem.fromJson(item.cast<String, dynamic>()))
              .where((item) => item.route.isNotEmpty)
              .toList()
        : const [];

    final rawDeepLinks = navigation['deep_links'];
    final deepLinks = <String, String>{};
    if (rawDeepLinks is Map) {
      for (final entry in rawDeepLinks.entries) {
        deepLinks['${entry.key}'] = '${entry.value}';
      }
    }

    return NavigationDefinition(
      drawer: list(navigation['drawer']),
      bottom: list(navigation['bottom']),
      tabs: list(navigation['tabs']),
      deepLinks: deepLinks,
    );
  }

  String? resolveDeepLink(String location) {
    for (final entry in deepLinks.entries) {
      if (location == entry.key || location.startsWith('${entry.key}?')) {
        return entry.value;
      }
    }
    return null;
  }
}
