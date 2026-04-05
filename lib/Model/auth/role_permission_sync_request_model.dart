import '../common/json_model.dart';

class RolePermissionSyncRequestModel implements JsonModel {
  const RolePermissionSyncRequestModel(this.data);

  final Map<String, dynamic> data;

  factory RolePermissionSyncRequestModel.fromJson(Map<String, dynamic> json) {
    return RolePermissionSyncRequestModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
