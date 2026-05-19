import '../../screen.dart';

class UserBranchAccessModel extends JsonModel {
  const UserBranchAccessModel({
    super.id,
    this.userId,
    this.branchId,
    this.isDefault,
    this.isActive,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  });
  final int? userId;
  final int? branchId;
  final bool? isDefault;
  final bool? isActive;
  final int? createdBy;
  final int? updatedBy;
  final String? createdAt;
  final String? updatedAt;

  factory UserBranchAccessModel.fromJson(Map<String, dynamic> json) {
    return UserBranchAccessModel(
      id: JsonModel.nullableInt(json['id']),
      userId: JsonModel.nullableInt(json['user_id']),
      branchId: JsonModel.nullableInt(json['branch_id']),
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
  String toString() => 'User Branch Access';


  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (userId != null) 'user_id': userId,
    if (branchId != null) 'branch_id': branchId,
    if (isDefault != null) 'is_default': isDefault,
    if (isActive != null) 'is_active': isActive,
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
