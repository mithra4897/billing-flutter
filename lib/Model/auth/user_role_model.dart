import '../../screen.dart';

class UserRoleModel extends JsonModel {
  const UserRoleModel({
    super.id,
    this.userId,
    this.roleId,
    this.isPrimaryRole,
    this.isActive,
    this.role,
  });
  final int? userId;
  final int? roleId;
  final bool? isPrimaryRole;
  final bool? isActive;
  final RoleModel? role;

  factory UserRoleModel.fromJson(Map<String, dynamic> json) {
    return UserRoleModel(
      id: JsonModel.nullableInt(json['id']),
      userId: JsonModel.nullableInt(json['user_id']),
      roleId:
          JsonModel.nullableInt(json['role_id']) ??
          JsonModel.nullableInt(
            (json['role'] as Map<String, dynamic>?)?['id'],
          ),
      isPrimaryRole: json['is_primary_role'] == null
          ? null
          : JsonModel.boolOf(json['is_primary_role']),
      isActive: json['is_active'] == null
          ? null
          : JsonModel.boolOf(json['is_active']),
      role: json['role'] is Map<String, dynamic>
          ? RoleModel.fromJson(json['role'] as Map<String, dynamic>)
          : null,
    );
  }
  @override
  String toString() => 'User Role';


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
