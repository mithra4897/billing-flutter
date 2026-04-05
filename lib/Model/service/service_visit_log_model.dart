import '../common/json_model.dart';

class ServiceVisitLogModel implements JsonModel {
  const ServiceVisitLogModel(this.data);

  final Map<String, dynamic> data;

  factory ServiceVisitLogModel.fromJson(Map<String, dynamic> json) {
    return ServiceVisitLogModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
