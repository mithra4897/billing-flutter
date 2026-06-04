String normalizeDateValue(String? value) {
  final text = (value ?? '').trim();
  if (text.isEmpty) {
    return '';
  }

  return text.length >= 10 ? text.substring(0, 10) : text;
}
