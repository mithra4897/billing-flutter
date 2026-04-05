import '../common/json_model.dart';

class MaintenanceWorkOrderServiceModel implements JsonModel {
  const MaintenanceWorkOrderServiceModel(this.data);

  final Map<String, dynamic> data;

  factory MaintenanceWorkOrderServiceModel.fromJson(Map<String, dynamic> json) {
    return MaintenanceWorkOrderServiceModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
