import '../common/json_model.dart';

class QcResultActionModel implements JsonModel {
  const QcResultActionModel(this.data);

  final Map<String, dynamic> data;

  factory QcResultActionModel.fromJson(Map<String, dynamic> json) {
    return QcResultActionModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
