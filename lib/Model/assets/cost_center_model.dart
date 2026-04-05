import '../common/json_model.dart';

class CostCenterModel implements JsonModel {
  const CostCenterModel(this.data);

  final Map<String, dynamic> data;

  factory CostCenterModel.fromJson(Map<String, dynamic> json) {
    return CostCenterModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
