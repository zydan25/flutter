import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_server_driven_runtime/data/local/cache_policy.dart';

void main() {
  test('fresh cache remains fresh inside ttl', () {
    const policy = CachePolicy(ttl: Duration(minutes: 10));
    final now = DateTime.utc(2026, 1, 1, 12);
    expect(policy.isFresh(DateTime.utc(2026, 1, 1, 11, 55), now), isTrue);
    expect(policy.isFresh(DateTime.utc(2026, 1, 1, 11), now), isFalse);
  });

  test('network only never uses cache', () {
    const policy = CachePolicy(mode: CacheMode.networkOnly);
    expect(policy.shouldUseCache(DateTime.now(), DateTime.now()), isFalse);
  });
}
