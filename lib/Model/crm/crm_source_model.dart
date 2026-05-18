import '../../screen.dart';

class CrmSourceModel implements JsonModel {
  const CrmSourceModel({
    this.id,
    this.sourceName,
    this.isActive,
    this.createdAt,
    this.updatedAt,
    Map<String, dynamic>? raw,
  }) : _raw = raw;

  final int? id;
  final String? sourceName;
  final bool? isActive;
  final String? createdAt;
  final String? updatedAt;

  factory CrmSourceModel.fromJson(Map<String, dynamic> json) {
    return CrmSourceModel(
      id: ModelValue.nullableInt(json['id']),
      sourceName: json['source_name']?.toString(),
      isActive: json['is_active'] == null
          ? null
          : ModelValue.boolOf(json['is_active']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (sourceName != null) 'source_name': sourceName,
    if (isActive != null) 'is_active': isActive,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
