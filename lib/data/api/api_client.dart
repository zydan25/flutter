import 'package:dio/dio.dart';

import '../../core/runtime_config.dart';
import 'api_errors.dart';

class ApiResult<T> {
  const ApiResult({
    required this.statusCode,
    required this.data,
    this.headers = const {},
  });

  final int statusCode;
  final T? data;
  final Map<String, List<String>> headers;
}

class ApiClient {
  ApiClient({Dio? dio, this._accessTokenProvider, this._onUnauthorized})
    : dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: RuntimeConfig.baseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 20),
            ),
          );

  final Dio dio;
  final Future<String?> Function()? _accessTokenProvider;
  final Future<bool> Function()? _onUnauthorized;

  Future<Response<dynamic>> request({
    required String method,
    required String path,
    Map<String, dynamic>? query,
    Map<String, dynamic>? pathParameters,
    Map<String, dynamic>? headers,
    dynamic body,
    int retries = 2,
    bool retryAfterUnauthorized = true,
  }) async {
    var resolvedPath = path;
    for (final entry
        in pathParameters?.entries ?? const <MapEntry<String, dynamic>>[]) {
      resolvedPath = resolvedPath.replaceAll(
        '{${entry.key}}',
        Uri.encodeComponent('${entry.value}'),
      );
    }
    final token = await _accessTokenProvider?.call();
    final mergedHeaders = <String, dynamic>{
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      ...?headers,
    };

    var unauthorizedRecovered = false;
    DioException? last;
    for (var attempt = 0; attempt <= retries; attempt++) {
      try {
        final response = await dio.request<dynamic>(
          resolvedPath,
          data: body,
          queryParameters: query,
          options: Options(
            method: method.toUpperCase(),
            headers: mergedHeaders,
          ),
        );
        return response;
      } on DioException catch (error) {
        last = error;
        final unauthorizedHandler = _onUnauthorized;
        if (error.response?.statusCode == 401 &&
            retryAfterUnauthorized &&
            !unauthorizedRecovered &&
            unauthorizedHandler != null) {
          unauthorizedRecovered = true;
          final recovered = await unauthorizedHandler();
          if (recovered) {
            final refreshedToken = await _accessTokenProvider?.call();
            if (refreshedToken != null && refreshedToken.isNotEmpty) {
              mergedHeaders['Authorization'] = 'Bearer $refreshedToken';
              attempt = -1;
            }
            continue;
          }
        }

        final status = error.response?.statusCode ?? 0;
        final retryable =
            error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout ||
            status >= 500;
        if (!retryable || attempt == retries) rethrow;
        await Future<void>.delayed(Duration(milliseconds: 250 * (attempt + 1)));
      }
    }
    throw last ?? StateError('Request failed');
  }

  Future<ApiResult<T>> requestMapped<T>({
    required String method,
    required String path,
    T Function(dynamic value)? map,
    Map<String, dynamic>? query,
    Map<String, dynamic>? pathParameters,
    Map<String, dynamic>? headers,
    dynamic body,
  }) async {
    final response = await request(
      method: method,
      path: path,
      query: query,
      pathParameters: pathParameters,
      headers: headers,
      body: body,
    );
    return ApiResult<T>(
      statusCode: response.statusCode ?? 0,
      data: map == null ? response.data as T? : map(response.data),
      headers: response.headers.map,
    );
  }

  Future<T> requestTyped<T>({
    required String method,
    required String path,
    required T Function(dynamic value) map,
    Map<String, dynamic>? query,
    Map<String, dynamic>? pathParameters,
    Map<String, dynamic>? headers,
    dynamic body,
    ApiError Function(dynamic data, int? statusCode)? mapError,
  }) async {
    try {
      final response = await request(
        method: method,
        path: path,
        query: query,
        pathParameters: pathParameters,
        headers: headers,
        body: body,
      );
      final status = response.statusCode ?? 0;
      if (status >= 400) {
        final error = mapError?.call(response.data, status) ??
            ApiError(
              kind: 'http',
              message: 'Request failed with status $status',
              statusCode: status,
              details: response.data,
            );
        throw ApiException(error);
      }
      return map(response.data);
    } on ApiException {
      rethrow;
    } on DioException catch (error) {
      final errorModel = mapError?.call(
            error.response?.data,
            error.response?.statusCode,
          ) ??
          ApiError(
            kind: 'network',
            message: error.message ?? 'Network request failed',
            statusCode: error.response?.statusCode,
            details: error.response?.data,
          );
      throw ApiException(errorModel);
    }
  }
}
