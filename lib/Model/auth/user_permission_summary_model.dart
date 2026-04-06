import '../common/json_model.dart';
import '../admin/user_model.dart';
import 'user_permission_model.dart';
import 'user_role_model.dart';

class UserPermissionSummaryModel implements JsonModel {
  const UserPermissionSummaryModel({
    this.user,
    this.roles = const [],
    this.rolePermissions = const [],
    this.directPermissions = const [],
    this.effectivePermissions = const [],
  });

  final UserModel? user;
  final List<UserRoleModel> roles;
  final List<UserPermissionModel> rolePermissions;
  final List<UserPermissionModel> directPermissions;
  final List<UserPermissionModel> effectivePermissions;

  factory UserPermissionSummaryModel.fromJson(Map<String, dynamic> json) {
    return UserPermissionSummaryModel(
      user: json['user'] is Map<String, dynamic>
          ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      roles: _roles(json['roles']),
      rolePermissions: _permissions(json['role_permissions']),
      directPermissions: _permissions(json['direct_permissions']),
      effectivePermissions: _permissions(json['effective_permissions']),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      if (user != null) 'user': user!.toJson(),
      'roles': roles.map((item) => item.toJson()).toList(growable: false),
      'role_permissions': rolePermissions
          .map((item) => item.toJson())
          .toList(growable: false),
      'direct_permissions': directPermissions
          .map((item) => item.toJson())
          .toList(growable: false),
      'effective_permissions': effectivePermissions
          .map((item) => item.toJson())
          .toList(growable: false),
    };
  }

  static List<UserRoleModel> _roles(dynamic value) {
    if (value is! List) {
      return const <UserRoleModel>[];
    }

    return value
        .whereType<Map<String, dynamic>>()
        .map(UserRoleModel.fromJson)
        .toList(growable: false);
  }

  static List<UserPermissionModel> _permissions(dynamic value) {
    if (value is! List) {
      return const <UserPermissionModel>[];
    }

    return value
        .whereType<Map<String, dynamic>>()
        .map(UserPermissionModel.fromJson)
        .toList(growable: false);
  }
}
