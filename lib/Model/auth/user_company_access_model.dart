import '../../screen.dart';

class UserCompanyAccessModel implements JsonModel {
  const UserCompanyAccessModel({
    this.id,
    this.userId,
    this.companyId,
    this.isDefault,
    this.isActive,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final int? userId;
  final int? companyId;
  final bool? isDefault;
  final bool? isActive;
  final int? createdBy;
  final int? updatedBy;
  final String? createdAt;
  final String? updatedAt;

  factory UserCompanyAccessModel.fromJson(Map<String, dynamic> json) {
    return UserCompanyAccessModel(
      id: ModelValue.nullableInt(json['id']),
      userId: ModelValue.nullableInt(json['user_id']),
      companyId: ModelValue.nullableInt(json['company_id']),
      isDefault: json['is_default'] == null
          ? null
          : ModelValue.boolOf(json['is_default']),
      isActive: json['is_active'] == null
          ? null
          : ModelValue.boolOf(json['is_active']),
      createdBy: ModelValue.nullableInt(json['created_by']),
      updatedBy: ModelValue.nullableInt(json['updated_by']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (userId != null) 'user_id': userId,
    if (companyId != null) 'company_id': companyId,
    if (isDefault != null) 'is_default': isDefault,
    if (isActive != null) 'is_active': isActive,
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
