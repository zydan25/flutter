class ApiError {
  const ApiError({
    required this.kind,
    required this.message,
    this.statusCode,
    this.details,
  });

  final String kind;
  final String message;
  final int? statusCode;
  final dynamic details;

  @override
  String toString() =>
      'ApiError(kind: $kind, statusCode: $statusCode, message: $message)';
}

class ApiException implements Exception {
  const ApiException(this.error);

  final ApiError error;

  @override
  String toString() => error.toString();
}
