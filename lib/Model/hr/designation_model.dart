import '../common/json_model.dart';

class DesignationModel implements JsonModel {
  const DesignationModel({
    this.id,
    this.designationName,
    this.isActive = true,
    this.raw,
  });

  final int? id;
  final String? designationName;
  final bool isActive;
  final Map<String, dynamic>? raw;

  @override
  String toString() => designationName ?? 'New Designation';

  factory DesignationModel.fromJson(Map<String, dynamic> json) {
    return DesignationModel(
      id: _nullableInt(json['id']),
      designationName: json['designation_name']?.toString(),
      isActive: _bool(json['is_active'], fallback: true),
      raw: json,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (designationName != null) 'designation_name': designationName,
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
