import '../data/api/api_client.dart';

class RemoteOption {
  const RemoteOption({required this.value, required this.label, this.extra = const {}});

  final dynamic value;
  final String label;
  final Map<String, dynamic> extra;

  factory RemoteOption.fromJson(
    Map<String, dynamic> json, {
    String valueKey = 'value',
    String labelKey = 'label',
  }) {
    return RemoteOption(
      value: json[valueKey],
      label: '${json[labelKey] ?? json[valueKey] ?? ''}',
      extra: json,
    );
  }
}

class RemoteOptionProvider {
  RemoteOptionProvider(this.api);

  final ApiClient api;

  Future<List<RemoteOption>> load({
    required String path,
    String method = 'GET',
    Map<String, dynamic>? query,
    String valueKey = 'value',
    String labelKey = 'label',
  }) async {
    final response = await api.request(
      method: method,
      path: path,
      query: query,
    );
    final raw = response.data;
    final values = raw is List
        ? raw
        : raw is Map && raw['items'] is List
            ? raw['items'] as List
            : raw is Map && raw['data'] is List
                ? raw['data'] as List
                : const [];

    return values
        .whereType<Map>()
        .map(
          (item) => RemoteOption.fromJson(
            item.cast<String, dynamic>(),
            valueKey: valueKey,
            labelKey: labelKey,
          ),
        )
        .toList(growable: false);
  }
}
