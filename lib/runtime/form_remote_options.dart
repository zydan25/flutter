import '../data/api/api_client.dart';

class RemoteOption {
  const RemoteOption({required this.value, required this.label});

  final dynamic value;
  final String label;

  factory RemoteOption.fromJson(Map<String, dynamic> json) => RemoteOption(
    value: json['value'] ?? json['id'],
    label: '${json['label'] ?? json['name'] ?? json['title'] ?? ''}',
  );
}

class RemoteOptionProvider {
  const RemoteOptionProvider(this.api);

  final ApiClient api;

  Future<List<RemoteOption>> load({
    required String url,
    String method = 'GET',
    Map<String, dynamic>? query,
    dynamic body,
    String dataPath = '',
  }) async {
    final response = await api.request(
      method: method,
      path: url,
      query: query,
      body: body,
    );
    dynamic data = response.data;
    if (dataPath.isNotEmpty) {
      for (final part in dataPath.split('.')) {
        if (data is Map) {
          data = data[part];
        } else {
          data = null;
          break;
        }
      }
    }
    final list = data is List ? data : const [];
    return list
        .whereType<Map>()
        .map((item) => RemoteOption.fromJson(item.cast<String, dynamic>()))
        .toList();
  }
}
