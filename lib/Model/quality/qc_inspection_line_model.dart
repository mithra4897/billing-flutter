import '../common/json_model.dart';

class QcInspectionLineModel implements JsonModel {
  const QcInspectionLineModel(this.data);

  final Map<String, dynamic> data;

  factory QcInspectionLineModel.fromJson(Map<String, dynamic> json) {
    return QcInspectionLineModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
