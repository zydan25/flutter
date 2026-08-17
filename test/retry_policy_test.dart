import 'package:flutter_test/flutter_test.dart';
import 'package:dynamic_flutter_app/sync/retry_policy.dart';

void main() {
  test('retry policy increases delay and respects cap', () {
    const policy = RetryPolicy(
      baseDelay: Duration(seconds: 2),
      maxDelay: Duration(seconds: 10),
    );

    expect(policy.canRetry(0), isTrue);
    expect(policy.canRetry(6), isFalse);
    expect(policy.delayFor(0), const Duration(seconds: 2));
    expect(policy.delayFor(1), const Duration(seconds: 4));
    expect(policy.delayFor(3), const Duration(seconds: 10));
  });
}
