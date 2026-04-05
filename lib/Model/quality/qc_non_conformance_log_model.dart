import '../common/json_model.dart';

class QcNonConformanceLogModel implements JsonModel {
  const QcNonConformanceLogModel(this.data);

  final Map<String, dynamic> data;

  factory QcNonConformanceLogModel.fromJson(Map<String, dynamic> json) {
    return QcNonConformanceLogModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
