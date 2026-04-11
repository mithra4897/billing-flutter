import '../common/json_model.dart';

class DepartmentModel implements JsonModel {
  const DepartmentModel({
    this.id,
    this.departmentName,
    this.isActive = true,
    this.raw,
  });

  final int? id;
  final String? departmentName;
  final bool isActive;
  final Map<String, dynamic>? raw;

  @override
  String toString() => departmentName ?? 'New Department';

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentModel(
      id: _nullableInt(json['id']),
      departmentName: json['department_name']?.toString(),
      isActive: _bool(json['is_active'], fallback: true),
      raw: json,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (departmentName != null) 'department_name': departmentName,
      'is_active': isActive,
    };
  }

  static int? _nullableInt(dynamic value) =>
      int.tryParse(value?.toString() ?? '');

  static bool _bool(dynamic value, {bool fallback = false}) {
    if (value == null) return fallback;
    return value == true || value == 1 || value.toString() == '1';
  }
}
