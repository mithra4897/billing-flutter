import '../common/json_model.dart';
import '../common/model_value.dart';
import '../admin/role_model.dart';

class UserRoleModel implements JsonModel {
  const UserRoleModel({
    this.id,
    this.userId,
    this.roleId,
    this.isPrimaryRole,
    this.isActive,
    this.role,
  });

  final int? id;
  final int? userId;
  final int? roleId;
  final bool? isPrimaryRole;
  final bool? isActive;
  final RoleModel? role;

  factory UserRoleModel.fromJson(Map<String, dynamic> json) {
    return UserRoleModel(
      id: ModelValue.nullableInt(json['id']),
      userId: ModelValue.nullableInt(json['user_id']),
      roleId:
          ModelValue.nullableInt(json['role_id']) ??
          ModelValue.nullableInt(
            (json['role'] as Map<String, dynamic>?)?['id'],
          ),
      isPrimaryRole: json['is_primary_role'] == null
          ? null
          : ModelValue.boolOf(json['is_primary_role']),
      isActive: json['is_active'] == null
          ? null
          : ModelValue.boolOf(json['is_active']),
      role: json['role'] is Map<String, dynamic>
          ? RoleModel.fromJson(json['role'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (roleId != null) 'role_id': roleId,
      if (isPrimaryRole != null) 'is_primary_role': isPrimaryRole,
      if (isActive != null) 'is_active': isActive,
      if (role != null) 'role': role!.toJson(),
    };
  }
}
