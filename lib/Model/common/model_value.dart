class ModelValue {
  const ModelValue._();

  static int intOf(dynamic value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static int? nullableInt(dynamic value) {
    if (value == null) {
      return null;
    }

    return int.tryParse(value.toString());
  }

  static double doubleOf(dynamic value, {double fallback = 0}) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static double? nullableDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }

  static bool boolOf(dynamic value, {bool fallback = false}) {
    if (value is bool) {
      return value;
    }

    final normalized = value?.toString().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      return fallback;
    }

    return normalized == '1' ||
        normalized == 'true' ||
        normalized == 'yes' ||
        normalized == 'active';
  }

  static String stringOf(dynamic value, {String fallback = ''}) {
    final text = value?.toString();
    return text ?? fallback;
  }
}
