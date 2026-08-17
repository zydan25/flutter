import 'package:flutter_test/flutter_test.dart';
import 'package:dynamic_flutter_app/core/security_policy.dart';

void main() {
  const policy = RuntimeSecurityPolicy();

  test('requires HTTPS for runtime API', () {
    expect(policy.validateBaseUrl('https://example.com').scheme, 'https');
    expect(() => policy.validateBaseUrl('http://example.com'), throwsStateError);
  });

  test('redacts sensitive log fields', () {
    final sanitized = policy.sanitizeLogPayload({
      'access_token': 'secret',
      'name': 'Runtime',
      'password': 'pw',
    });
    expect(sanitized['access_token'], '[REDACTED]');
    expect(sanitized['password'], '[REDACTED]');
    expect(sanitized['name'], 'Runtime');
  });
}
