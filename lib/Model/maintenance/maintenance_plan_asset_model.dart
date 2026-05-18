import '../../screen.dart';

class MaintenancePlanAssetModel implements JsonModel {
  const MaintenancePlanAssetModel(this.data);

  final Map<String, dynamic> data;

  factory MaintenancePlanAssetModel.fromJson(Map<String, dynamic> json) {
    return MaintenancePlanAssetModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
