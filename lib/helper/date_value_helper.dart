String normalizeDateValue(String? value) {
  final text = (value ?? '').trim();
  if (text.isEmpty) {
    return '';
  }

  return text.length >= 10 ? text.substring(0, 10) : text;
}

DateTime? parseNormalizedDateValue(String? value) {
  final normalized = normalizeDateValue(value);
  if (normalized.isEmpty) {
    return null;
  }
  return DateTime.tryParse(normalized);
}

bool matchesDateValueRange(
  String? value, {
  String? fromValue,
  String? toValue,
}) {
  final fromDate = parseNormalizedDateValue(fromValue);
  final toDate = parseNormalizedDateValue(toValue);
  if (fromDate == null && toDate == null) {
    return true;
  }

  final candidate = parseNormalizedDateValue(value);
  if (candidate == null) {
    return false;
  }

  if (fromDate != null && candidate.isBefore(fromDate)) {
    return false;
  }
  if (toDate != null && candidate.isAfter(toDate)) {
    return false;
  }
  return true;
}
