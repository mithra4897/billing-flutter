import '../common/json_model.dart';

class QcPlanLineModel implements JsonModel {
  const QcPlanLineModel(this.data);

  final Map<String, dynamic> data;

  factory QcPlanLineModel.fromJson(Map<String, dynamic> json) {
    return QcPlanLineModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
