class RetryPolicy {
  const RetryPolicy({
    this.maxAttempts = 6,
    this.baseDelay = const Duration(seconds: 2),
    this.maxDelay = const Duration(minutes: 10),
  });

  final int maxAttempts;
  final Duration baseDelay;
  final Duration maxDelay;

  bool canRetry(int retryCount) => retryCount < maxAttempts;

  Duration delayFor(int retryCount) {
    final exponent = retryCount.clamp(0, 10);
    final multiplier = 1 << exponent;
    final candidate = Duration(milliseconds: baseDelay.inMilliseconds * multiplier);
    return candidate > maxDelay ? maxDelay : candidate;
  }
}
