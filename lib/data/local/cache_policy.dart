enum CacheMode { cacheFirst, networkFirst, staleWhileRevalidate, networkOnly }

class CachePolicy {
  const CachePolicy({
    this.mode = CacheMode.cacheFirst,
    this.ttl = const Duration(minutes: 30),
    this.allowStale = true,
  });

  final CacheMode mode;
  final Duration ttl;
  final bool allowStale;

  bool isFresh(DateTime? updatedAt, DateTime now) {
    if (updatedAt == null) return false;
    return now.toUtc().difference(updatedAt.toUtc()) <= ttl;
  }

  bool shouldUseCache(DateTime? updatedAt, DateTime now) {
    switch (mode) {
      case CacheMode.cacheFirst:
        return true;
      case CacheMode.networkFirst:
        return allowStale && !isFresh(updatedAt, now);
      case CacheMode.staleWhileRevalidate:
        return true;
      case CacheMode.networkOnly:
        return false;
    }
  }
}
