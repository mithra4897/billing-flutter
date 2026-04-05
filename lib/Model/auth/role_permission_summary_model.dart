import '../common/json_model.dart';

class RolePermissionSummaryModel implements JsonModel {
  const RolePermissionSummaryModel(this.data);

  final Map<String, dynamic> data;

  factory RolePermissionSummaryModel.fromJson(Map<String, dynamic> json) {
    return RolePermissionSummaryModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
