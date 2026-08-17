class RuntimeSecurityPolicy {
  const RuntimeSecurityPolicy({
    this.allowInsecureHttp = false,
    this.allowExternalHosts = false,
  });

  final bool allowInsecureHttp;
  final bool allowExternalHosts;

  Uri validateBaseUrl(String raw) {
    final uri = Uri.tryParse(raw);
    if (uri == null || uri.scheme.isEmpty || uri.host.isEmpty) {
      throw const FormatException('Invalid runtime base URL');
    }
    if (!allowInsecureHttp && uri.scheme != 'https') {
      throw StateError('Runtime API must use HTTPS');
    }
    return uri;
  }

  Uri validateExternalUrl(String raw, {String? allowedHost}) {
    final uri = Uri.tryParse(raw);
    if (uri == null || uri.scheme.isEmpty || uri.host.isEmpty) {
      throw const FormatException('Invalid external URL');
    }
    if (!const {'https', 'http'}.contains(uri.scheme)) {
      throw StateError('Unsupported external URL scheme');
    }
    if (!allowExternalHosts && allowedHost != null && uri.host != allowedHost) {
      throw StateError('External host is not allowed');
    }
    return uri;
  }

  Map<String, dynamic> sanitizeLogPayload(Map<String, dynamic> payload) {
    const sensitive = {
      'access_token',
      'refresh_token',
      'authorization',
      'password',
      'secret',
      'api_key',
    };
    return payload.map(
      (key, value) => MapEntry(
        key,
        sensitive.contains(key.toLowerCase()) ? '[REDACTED]' : value,
      ),
    );
  }
}
