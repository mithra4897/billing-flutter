import '../../screen.dart';

class CrmSourceModel extends JsonModel {
  const CrmSourceModel({
    super.id,
    this.sourceName,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });
  final String? sourceName;
  final bool? isActive;
  final String? createdAt;
  final String? updatedAt;

  factory CrmSourceModel.fromJson(Map<String, dynamic> json) {
    return CrmSourceModel(
      id: JsonModel.nullableInt(json['id']),
      sourceName: json['source_name']?.toString(),
      isActive: json['is_active'] == null
          ? null
          : JsonModel.boolOf(json['is_active']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
  @override
  String toString() => 'Crm Source';


  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (sourceName != null) 'source_name': sourceName,
    if (isActive != null) 'is_active': isActive,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
