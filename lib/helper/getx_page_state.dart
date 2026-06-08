int _persistentControllerSessionScope = 0;

void advancePersistentControllerSessionScope() {
  _persistentControllerSessionScope++;
}

Map<String, Object?> uniqueControllerScope([
  Map<String, Object?> scope = const <String, Object?>{},
]) {
  return <String, Object?>{
    'instance': DateTime.now().microsecondsSinceEpoch,
    ...scope,
  };
}

String persistentControllerTag(
  String controllerName, {
  Map<String, Object?> scope = const <String, Object?>{},
}) {
  final sessionScope = _persistentControllerSessionScope;
  if (scope.isEmpty) {
    return '$controllerName#session=$sessionScope';
  }

  final parts =
      scope.entries
          .where((entry) => entry.value != null)
          .map((entry) => MapEntry(entry.key, entry.value))
          .toList(growable: false)
        ..sort((left, right) => left.key.compareTo(right.key));

  if (parts.isEmpty) {
    return '$controllerName#session=$sessionScope';
  }

  final suffix = parts.map((entry) => '${entry.key}=${entry.value}').join('&');
  return '$controllerName#$suffix&session=$sessionScope';
}

List<T> filterBySearchAndStatus<T>(
  Iterable<T> items, {
  required String query,
  required String status,
  required String? Function(T item) statusOf,
  required Iterable<String?> Function(T item) searchFieldsOf,
}) {
  final normalizedQuery = query.trim().toLowerCase();
  return items
      .where((item) {
        final currentStatus = statusOf(item) ?? '';
        final statusOk = status.isEmpty || currentStatus == status;
        if (!statusOk) {
          return false;
        }
        if (normalizedQuery.isEmpty) {
          return true;
        }
        final haystack = searchFieldsOf(
          item,
        ).whereType<String>().join(' ').toLowerCase();
        return haystack.contains(normalizedQuery);
      })
      .toList(growable: false);
}
