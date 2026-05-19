import '../../screen.dart';

class PartyTypeModel extends JsonModel {
  const PartyTypeModel({
    super.id,
    this.code,
    this.name,
    this.isSystem,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });
  final String? code;
  final String? name;
  final bool? isSystem;
  final bool? isActive;
  final String? createdAt;
  final String? updatedAt;

  factory PartyTypeModel.fromJson(Map<String, dynamic> json) {
    return PartyTypeModel(
      id: ModelValue.nullableInt(json['id']),
      code: json['code']?.toString(),
      name: json['name']?.toString(),
      isSystem: json['is_system'] == null
          ? null
          : ModelValue.boolOf(json['is_system']),
      isActive: json['is_active'] == null
          ? null
          : ModelValue.boolOf(json['is_active']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
  @override
  String toString() => 'Party Type';


  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (code != null) 'code': code,
    if (name != null) 'name': name,
    if (isSystem != null) 'is_system': isSystem,
    if (isActive != null) 'is_active': isActive,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
