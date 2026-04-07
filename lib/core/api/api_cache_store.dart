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
}
