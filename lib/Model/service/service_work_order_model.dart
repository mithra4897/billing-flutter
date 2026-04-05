import '../common/json_model.dart';

class ServiceWorkOrderModel implements JsonModel {
  const ServiceWorkOrderModel(this.data);

  final Map<String, dynamic> data;

  factory ServiceWorkOrderModel.fromJson(Map<String, dynamic> json) {
    return ServiceWorkOrderModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
