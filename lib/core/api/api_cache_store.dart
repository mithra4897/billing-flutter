class ApiCacheEntry {
  const ApiCacheEntry({
    required this.body,
    required this.storedAt,
    required this.expiresAt,
    required this.etag,
  });

  final String body;
  final String etag;
  final DateTime storedAt;
  final DateTime expiresAt;

  bool isExpiredAt(DateTime value) => !value.isBefore(expiresAt);
}

class ApiCacheDiagnostics {
  const ApiCacheDiagnostics({
    required this.entries,
    required this.bodyCharacters,
    required this.hits,
    required this.misses,
    required this.evictions,
    required this.expirations,
  });

  final int entries;
  final int bodyCharacters;
  final int hits;
  final int misses;
  final int evictions;
  final int expirations;

  double get hitRate {
    final reads = hits + misses;
    return reads == 0 ? 0 : hits / reads;
  }
}

/// Small, process-local cache used only for conditional GET responses.
///
/// Entries are user/context scoped by [ApiClient], bounded by count and total
/// response size, and expire automatically. This cache is intentionally not
/// persisted because authenticated response bodies must not survive a session.
class ApiCacheStore {
  ApiCacheStore._();

  static const Duration defaultTtl = Duration(minutes: 10);
  static const int maxEntries = 200;
  static const int maxBodyCharacters = 8 * 1024 * 1024;

  static final Map<String, ApiCacheEntry> _entries = <String, ApiCacheEntry>{};
  static int _bodyCharacters = 0;
  static int _hits = 0;
  static int _misses = 0;
  static int _evictions = 0;
  static int _expirations = 0;

  static ApiCacheEntry? read(String key) {
    _removeExpired();
    final entry = _entries.remove(key);
    if (entry == null) {
      _misses++;
      return null;
    }

    // Reinsert so the map maintains least-recently-used ordering.
    _entries[key] = entry;
    _hits++;
    return entry;
  }

  static int get entryCount {
    _removeExpired();
    return _entries.length;
  }

  static DateTime? get lastStoredAt {
    _removeExpired();
    DateTime? latest;
    for (final entry in _entries.values) {
      final storedAt = entry.storedAt;
      if (latest == null || storedAt.isAfter(latest)) {
        latest = storedAt;
      }
    }
    return latest;
  }

  static int get etagEntryCount {
    _removeExpired();
    return _entries.length;
  }

  static ApiCacheDiagnostics get diagnostics {
    _removeExpired();
    return ApiCacheDiagnostics(
      entries: _entries.length,
      bodyCharacters: _bodyCharacters,
      hits: _hits,
      misses: _misses,
      evictions: _evictions,
      expirations: _expirations,
    );
  }

  static void write(
    String key, {
    required String body,
    required String? etag,
    Duration ttl = defaultTtl,
  }) {
    final normalizedEtag = etag?.trim() ?? '';
    if (normalizedEtag.isEmpty ||
        body.isEmpty ||
        body.length > maxBodyCharacters ||
        ttl <= Duration.zero) {
      remove(key);
      return;
    }

    _removeExpired();
    remove(key);
    final now = DateTime.now();
    _entries[key] = ApiCacheEntry(
      body: body,
      etag: normalizedEtag,
      storedAt: now,
      expiresAt: now.add(ttl),
    );
    _bodyCharacters += body.length;
    _enforceLimits();
  }

  static void remove(String key) {
    final removed = _entries.remove(key);
    if (removed != null) {
      _bodyCharacters -= removed.body.length;
    }
  }

  static void removeWhere(bool Function(String key, ApiCacheEntry entry) test) {
    _removeExpired();
    final keysToRemove = _entries.entries
        .where((entry) => test(entry.key, entry.value))
        .map((entry) => entry.key)
        .toList(growable: false);

    for (final key in keysToRemove) {
      remove(key);
    }
  }

  static void clear({bool resetDiagnostics = true}) {
    _entries.clear();
    _bodyCharacters = 0;
    if (resetDiagnostics) {
      _hits = 0;
      _misses = 0;
      _evictions = 0;
      _expirations = 0;
    }
  }

  static Map<String, int> familyCounts() {
    _removeExpired();
    final counts = <String, int>{};
    for (final key in _entries.keys) {
      final parts = key.split('|');
      final path = parts.length >= 9
          ? parts[7]
          : (parts.length >= 8 ? parts[6] : key);
      counts[path] = (counts[path] ?? 0) + 1;
    }
    final sortedEntries = counts.entries.toList(growable: false)
      ..sort((left, right) {
        final byCount = right.value.compareTo(left.value);
        if (byCount != 0) {
          return byCount;
        }
        return left.key.compareTo(right.key);
      });
    return Map<String, int>.fromEntries(sortedEntries);
  }

  static void _removeExpired() {
    if (_entries.isEmpty) {
      return;
    }
    final now = DateTime.now();
    final expiredKeys = _entries.entries
        .where((entry) => entry.value.isExpiredAt(now))
        .map((entry) => entry.key)
        .toList(growable: false);
    for (final key in expiredKeys) {
      remove(key);
      _expirations++;
    }
  }

  static void _enforceLimits() {
    while (_entries.length > maxEntries ||
        _bodyCharacters > maxBodyCharacters) {
      if (_entries.isEmpty) {
        break;
      }
      remove(_entries.keys.first);
      _evictions++;
    }
  }
}
