import '../admin/role_model.dart';
import '../common/json_model.dart';
import 'role_permission_model.dart';

class RolePermissionSummaryModel implements JsonModel {
  const RolePermissionSummaryModel({
    this.role,
    this.permissions = const <RolePermissionModel>[],
    this.raw,
  });

  final RoleModel? role;
  final List<RolePermissionModel> permissions;
  final Map<String, dynamic>? raw;

  factory RolePermissionSummaryModel.fromJson(Map<String, dynamic> json) {
    return RolePermissionSummaryModel(
      role: json['role'] is Map<String, dynamic>
          ? RoleModel.fromJson(json['role'] as Map<String, dynamic>)
          : null,
      permissions: _permissionList(json['permissions']),
      raw: json,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      if (role != null) 'role': role!.toJson(),
      'permissions': permissions
          .map((item) => item.toJson())
          .toList(growable: false),
    };
  }

  static List<RolePermissionModel> _permissionList(dynamic value) {
    if (value is! List) {
      return const <RolePermissionModel>[];
    }

    return value
        .whereType<Map<String, dynamic>>()
        .map(RolePermissionModel.fromJson)
        .toList(growable: false);
  }
}
