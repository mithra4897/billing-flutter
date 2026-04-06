import '../common/json_model.dart';
import 'role_permission_model.dart';

class RolePermissionSyncRequestModel implements JsonModel {
  const RolePermissionSyncRequestModel({
    this.permissions = const <RolePermissionModel>[],
  });

  final List<RolePermissionModel> permissions;

  factory RolePermissionSyncRequestModel.fromJson(Map<String, dynamic> json) {
    final rawPermissions = json['permissions'];
    return RolePermissionSyncRequestModel(
      permissions: rawPermissions is List
          ? rawPermissions
                .whereType<Map<String, dynamic>>()
                .map(RolePermissionModel.fromJson)
                .toList(growable: false)
          : const <RolePermissionModel>[],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'permissions': permissions
          .map((item) => item.toJson())
          .toList(growable: false),
    };
  }
}
