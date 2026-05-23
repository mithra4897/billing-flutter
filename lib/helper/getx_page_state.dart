String persistentControllerTag(
  String controllerName, {
  Map<String, Object?> scope = const <String, Object?>{},
}) {
  if (scope.isEmpty) {
    return controllerName;
  }

  final parts =
      scope.entries
          .where((entry) => entry.value != null)
          .map((entry) => MapEntry(entry.key, entry.value))
          .toList(growable: false)
        ..sort((left, right) => left.key.compareTo(right.key));

  if (parts.isEmpty) {
    return controllerName;
  }

  final suffix = parts.map((entry) => '${entry.key}=${entry.value}').join('&');
  return '$controllerName?$suffix';
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
