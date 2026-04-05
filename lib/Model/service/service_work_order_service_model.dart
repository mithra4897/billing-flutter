import '../common/json_model.dart';

class ServiceWorkOrderServiceModel implements JsonModel {
  const ServiceWorkOrderServiceModel(this.data);

  final Map<String, dynamic> data;

  factory ServiceWorkOrderServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceWorkOrderServiceModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
