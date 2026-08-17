import 'dart:async';

import 'cache_policy.dart';
import 'runtime_repository.dart';

class CacheRead<T> {
  const CacheRead({required this.value, required this.isStale});

  final T? value;
  final bool isStale;
}

/// Coordinates local-first reads and optional remote revalidation.
///
/// The coordinator never starts background work on its own. A caller chooses
/// when to revalidate, which keeps the runtime compatible with manual-only
/// synchronization rules.
class CacheCoordinator<T> {
  CacheCoordinator({required this.repository, this.policy = const CachePolicy()});

  final RuntimeRepository<T> repository;
  final CachePolicy policy;

  Future<CacheRead<T>> read({DateTime? now}) async {
    final value = await repository.get();
    final metadata = await repository.metadata();
    final updatedAt = DateTime.tryParse('${metadata?['updated_at'] ?? ''}');
    final fresh = policy.isFresh(updatedAt, now ?? DateTime.now().toUtc());
    return CacheRead(value: value, isStale: value != null && !fresh);
  }

  Future<T?> readAndRevalidate({
    required Future<T?> Function() fetch,
    Future<void> Function(T value)? persist,
    DateTime? now,
  }) async {
    final cached = await read(now: now);
    switch (policy.mode) {
      case CacheMode.cacheFirst:
        if (cached.value != null) return cached.value;
        final value = await fetch();
        if (value != null) await persist?.call(value);
        return value;
      case CacheMode.networkFirst:
        try {
          final value = await fetch();
          if (value != null) await persist?.call(value);
          return value ?? (policy.allowStale ? cached.value : null);
        } catch (_) {
          if (policy.allowStale) return cached.value;
          rethrow;
        }
      case CacheMode.staleWhileRevalidate:
        if (cached.value != null) {
          unawaited(_revalidate(fetch, persist));
          return cached.value;
        }
        final value = await fetch();
        if (value != null) await persist?.call(value);
        return value;
      case CacheMode.networkOnly:
        final value = await fetch();
        if (value != null) await persist?.call(value);
        return value;
    }
  }

  Future<void> invalidate() => repository.store.deleteResource(repository.resourceId);

  Future<void> _revalidate(
    Future<T?> Function() fetch,
    Future<void> Function(T value)? persist,
  ) async {
    try {
      final value = await fetch();
      if (value != null) await persist?.call(value);
    } catch (_) {
      // SWR revalidation is best-effort; cached data remains usable.
    }
  }
}
