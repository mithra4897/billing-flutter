import '../common/json_model.dart';
import '../common/model_value.dart';
import '../auth/role_permission_model.dart';
import 'permission_model.dart';

class RoleModel implements JsonModel {
  const RoleModel({
    this.id,
    this.code,
    this.name,
    this.description,
    this.isSystemRole,
    this.isActive,
    this.permissions = const [],
    this.rolePermissions = const [],
    this.permissionIds = const [],
    this.raw,
  });

  final int? id;
  final String? code;
  final String? name;
  final String? description;
  final bool? isSystemRole;
  final bool? isActive;
  final List<PermissionModel> permissions;
  final List<RolePermissionModel> rolePermissions;
  final List<int> permissionIds;
  final Map<String, dynamic>? raw;

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(
      id: ModelValue.nullableInt(json['id']),
      code: json['code']?.toString(),
      name: json['name']?.toString(),
      description: json['description']?.toString(),
      isSystemRole: json['is_system_role'] == null
          ? null
          : ModelValue.boolOf(json['is_system_role']),
      isActive: json['is_active'] == null
          ? null
          : ModelValue.boolOf(json['is_active']),
      permissions: _permissionList(json['permissions']),
      rolePermissions: _rolePermissionList(json['role_permissions']),
      permissionIds: _permissionIdList(json['permission_ids']),
      raw: json,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (code != null) 'code': code,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (isSystemRole != null) 'is_system_role': isSystemRole,
      if (isActive != null) 'is_active': isActive,
      if (permissionIds.isNotEmpty) 'permission_ids': permissionIds,
    };
  }

  static List<PermissionModel> _permissionList(dynamic value) {
    if (value is! List) {
      return const <PermissionModel>[];
    }

    return value
        .whereType<Map<String, dynamic>>()
        .map(PermissionModel.fromJson)
        .toList(growable: false);
  }

  static List<int> _permissionIdList(dynamic value) {
    if (value is! List) {
      return const <int>[];
    }

    return value.map(ModelValue.intOf).toList(growable: false);
  }

  static List<RolePermissionModel> _rolePermissionList(dynamic value) {
    if (value is! List) {
      return const <RolePermissionModel>[];
    }

    return value
        .whereType<Map<String, dynamic>>()
        .map(RolePermissionModel.fromJson)
        .toList(growable: false);
  }
}
