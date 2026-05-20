String persistentControllerTag(
  String controllerName, {
  Map<String, Object?> scope = const <String, Object?>{},
}) {
  if (scope.isEmpty) {
    return controllerName;
  }

  final parts = scope.entries
      .where((entry) => entry.value != null)
      .map((entry) => MapEntry(entry.key, entry.value))
      .toList(growable: false)
    ..sort((left, right) => left.key.compareTo(right.key));

  if (parts.isEmpty) {
    return controllerName;
  }

  final suffix = parts
      .map((entry) => '${entry.key}=${entry.value}')
      .join('&');
  return '$controllerName?$suffix';
}
