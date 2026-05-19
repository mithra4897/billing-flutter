import '../../screen.dart';

class RolePermissionSyncRequestModel extends JsonModel {
  const RolePermissionSyncRequestModel({
    this.permissions = const <RolePermissionModel>[],
  }) : super(id: null);

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
  String toString() => 'Role Permission Sync Request';


  @override
  Map<String, dynamic> toJson() {
    return {
      'permissions': permissions
          .map((item) => item.toJson())
          .toList(growable: false),
    };
  }
}
