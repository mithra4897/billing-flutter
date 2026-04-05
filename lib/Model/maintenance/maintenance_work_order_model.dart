import '../common/json_model.dart';

class MaintenanceWorkOrderModel implements JsonModel {
  const MaintenanceWorkOrderModel(this.data);

  final Map<String, dynamic> data;

  factory MaintenanceWorkOrderModel.fromJson(Map<String, dynamic> json) {
    return MaintenanceWorkOrderModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
