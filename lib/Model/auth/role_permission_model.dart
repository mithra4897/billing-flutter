import '../common/json_model.dart';

class RolePermissionModel implements JsonModel {
  const RolePermissionModel(this.data);

  final Map<String, dynamic> data;

  factory RolePermissionModel.fromJson(Map<String, dynamic> json) {
    return RolePermissionModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
