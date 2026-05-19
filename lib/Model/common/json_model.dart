abstract class JsonModel {
  final int? id;

  Map<String, dynamic> toJson();

  const JsonModel({this.id});

  @override
  String toString();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JsonModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => Object.hash(runtimeType, id);

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

    final normalized = value?.toString().trim().toLowerCase();
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

  static String? nullableString(dynamic value) {
    return value?.toString();
  }

  static Map<String, dynamic>? mapOf(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return null;
  }

  static List<Map<String, dynamic>> mapListOf(dynamic value) {
    if (value is! List) {
      return const <Map<String, dynamic>>[];
    }

    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  static List<T> listOf<T>(
    dynamic value,
    T Function(Map<String, dynamic> json) mapper,
  ) {
    if (value is! List) {
      return <T>[];
    }

    return value
        .whereType<Map>()
        .map((item) => mapper(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  static List<String> stringListOf(dynamic value) {
    if (value is! List) {
      return const <String>[];
    }

    return value.map((item) => item.toString()).toList(growable: false);
  }
}
