extension StringNullableExtensions on String? {
  bool get isNullOrBlank => this == null || this!.trim().isEmpty;

  String get orEmpty => this ?? '';
}

extension StringExtensions on String {
  String get capitalized {
    if (trim().isEmpty) {
      return this;
    }

    return '${this[0].toUpperCase()}${substring(1)}';
  }

  String get titleCase {
    return split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .map((part) => part.capitalized)
        .join(' ');
  }
}

String displayDate(String? value) {
  if (value == null || value.trim().isEmpty) {
    return '';
  }

  return value.split('T').first.split(' ').first;
}

String displayDateTime(String? value) {
  if (value == null || value.trim().isEmpty) {
    return '';
  }

  final parsed = DateTime.tryParse(value.trim());
  if (parsed != null) {
    final local = parsed.isUtc ? parsed.toLocal() : parsed;
    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    final second = local.second.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute:$second';
  }

  final normalized = value.trim().replaceFirst('T', ' ');
  return normalized.endsWith('Z')
      ? normalized.substring(0, normalized.length - 1)
      : normalized;
}

String currentDateTimeInput() {
  return displayDateTime(DateTime.now().toIso8601String());
}
