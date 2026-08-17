import 'remote_option_provider.dart';

class FormOptionController {
  FormOptionController(this.provider);

  final RemoteOptionProvider provider;
  final Map<String, List<RemoteOption>> _cache = {};

  List<RemoteOption>? cached(String fieldName) => _cache[fieldName];

  Future<List<RemoteOption>> load({
    required String fieldName,
    required String path,
    String method = 'GET',
    Map<String, dynamic>? query,
    String valueKey = 'value',
    String labelKey = 'label',
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cache.containsKey(fieldName)) {
      return _cache[fieldName]!;
    }
    final options = await provider.load(
      path: path,
      method: method,
      query: query,
      valueKey: valueKey,
      labelKey: labelKey,
    );
    _cache[fieldName] = options;
    return options;
  }

  void invalidate(String fieldName) => _cache.remove(fieldName);

  void clear() => _cache.clear();
}
