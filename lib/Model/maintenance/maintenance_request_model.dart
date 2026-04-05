import '../common/json_model.dart';

class MaintenanceRequestModel implements JsonModel {
  const MaintenanceRequestModel(this.data);

  final Map<String, dynamic> data;

  factory MaintenanceRequestModel.fromJson(Map<String, dynamic> json) {
    return MaintenanceRequestModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
