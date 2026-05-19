import '../../screen.dart';

class UserCompanyAccessModel extends JsonModel {
  const UserCompanyAccessModel({
    super.id,
    this.userId,
    this.companyId,
    this.isDefault,
    this.isActive,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  });
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
      id: JsonModel.nullableInt(json['id']),
      userId: JsonModel.nullableInt(json['user_id']),
      companyId: JsonModel.nullableInt(json['company_id']),
      isDefault: json['is_default'] == null
          ? null
          : JsonModel.boolOf(json['is_default']),
      isActive: json['is_active'] == null
          ? null
          : JsonModel.boolOf(json['is_active']),
      createdBy: JsonModel.nullableInt(json['created_by']),
      updatedBy: JsonModel.nullableInt(json['updated_by']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
  @override
  String toString() => 'User Company Access';


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
