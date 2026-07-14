class ApiCacheEntry {
  const ApiCacheEntry({required this.body, required this.storedAt, this.etag});

  final String body;
  final String? etag;
  final DateTime storedAt;
}

class ApiCacheStore {
  ApiCacheStore._();

  static final Map<String, ApiCacheEntry> _entries = <String, ApiCacheEntry>{};

  static ApiCacheEntry? read(String key) => _entries[key];

  static int get entryCount => _entries.length;

  static DateTime? get lastStoredAt {
    DateTime? latest;
    for (final entry in _entries.values) {
      final storedAt = entry.storedAt;
      if (latest == null || storedAt.isAfter(latest)) {
        latest = storedAt;
      }
    }
    return latest;
  }

  static int get etagEntryCount =>
      _entries.values.where((entry) => (entry.etag ?? '').isNotEmpty).length;

  static void write(String key, {required String body, required String? etag}) {
    _entries[key] = ApiCacheEntry(
      body: body,
      etag: etag,
      storedAt: DateTime.now(),
    );
  }

  static void remove(String key) {
    _entries.remove(key);
  }

  static void removeWhere(bool Function(String key, ApiCacheEntry entry) test) {
    final keysToRemove = _entries.entries
        .where((entry) => test(entry.key, entry.value))
        .map((entry) => entry.key)
        .toList(growable: false);

    for (final key in keysToRemove) {
      _entries.remove(key);
    }
  }

  static void clear() {
    _entries.clear();
  }

  static Map<String, int> familyCounts() {
    final counts = <String, int>{};
    for (final key in _entries.keys) {
      final parts = key.split('|');
      final path = parts.length >= 7 ? parts[6] : key;
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
}
