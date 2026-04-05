import '../common/json_model.dart';

class MaintenancePlanModel implements JsonModel {
  const MaintenancePlanModel(this.data);

  final Map<String, dynamic> data;

  factory MaintenancePlanModel.fromJson(Map<String, dynamic> json) {
    return MaintenancePlanModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
