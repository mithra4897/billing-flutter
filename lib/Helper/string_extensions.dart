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
