import '../common/json_model.dart';

class MaintenanceWorkOrderSpareModel implements JsonModel {
  const MaintenanceWorkOrderSpareModel(this.data);

  final Map<String, dynamic> data;

  factory MaintenanceWorkOrderSpareModel.fromJson(Map<String, dynamic> json) {
    return MaintenanceWorkOrderSpareModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
