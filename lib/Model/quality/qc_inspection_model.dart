import '../common/json_model.dart';

class QcInspectionModel implements JsonModel {
  const QcInspectionModel(this.data);

  final Map<String, dynamic> data;

  factory QcInspectionModel.fromJson(Map<String, dynamic> json) {
    return QcInspectionModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
