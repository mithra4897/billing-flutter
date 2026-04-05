import '../common/json_model.dart';

class QcPlanModel implements JsonModel {
  const QcPlanModel(this.data);

  final Map<String, dynamic> data;

  factory QcPlanModel.fromJson(Map<String, dynamic> json) {
    return QcPlanModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
