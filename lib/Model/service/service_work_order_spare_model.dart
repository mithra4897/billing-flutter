import '../common/json_model.dart';

class ServiceWorkOrderSpareModel implements JsonModel {
  const ServiceWorkOrderSpareModel(this.data);

  final Map<String, dynamic> data;

  factory ServiceWorkOrderSpareModel.fromJson(Map<String, dynamic> json) {
    return ServiceWorkOrderSpareModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
