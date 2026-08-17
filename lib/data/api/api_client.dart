import 'package:dio/dio.dart';

import '../../core/runtime_config.dart';

class ApiClient {
  ApiClient({Dio? dio, Future<String?> Function()? accessTokenProvider})
      : _accessTokenProvider = accessTokenProvider,
        dio = dio ?? Dio(BaseOptions(baseUrl: RuntimeConfig.baseUrl, connectTimeout: const Duration(seconds: 15), receiveTimeout: const Duration(seconds: 20)));

  final Dio dio;
  final Future<String?> Function()? _accessTokenProvider;

  Future<Response<dynamic>> request({
    required String method,
    required String path,
    Map<String, dynamic>? query,
    Map<String, dynamic>? pathParameters,
    Map<String, dynamic>? headers,
    dynamic body,
    int retries = 2,
  }) async {
    var resolvedPath = path;
    for (final entry in pathParameters?.entries ?? const <MapEntry<String, dynamic>>[]) {
      resolvedPath = resolvedPath.replaceAll('{${entry.key}}', Uri.encodeComponent('${entry.value}'));
    }
    final token = await _accessTokenProvider?.call();
    final mergedHeaders = <String, dynamic>{
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      ...?headers,
    };
    DioException? last;
    for (var attempt = 0; attempt <= retries; attempt++) {
      try {
        return await dio.request<dynamic>(
          resolvedPath,
          data: body,
          queryParameters: query,
          options: Options(method: method.toUpperCase(), headers: mergedHeaders),
        );
      } on DioException catch (error) {
        last = error;
        final status = error.response?.statusCode ?? 0;
        final retryable = error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout ||
            status >= 500;
        if (!retryable || attempt == retries) rethrow;
        await Future<void>.delayed(Duration(milliseconds: 250 * (attempt + 1)));
      }
    }
    throw last ?? StateError('Request failed');
  }
}
