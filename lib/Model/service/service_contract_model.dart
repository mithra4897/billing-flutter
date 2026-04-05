import '../common/json_model.dart';

class ServiceContractModel implements JsonModel {
  const ServiceContractModel(this.data);

  final Map<String, dynamic> data;

  factory ServiceContractModel.fromJson(Map<String, dynamic> json) {
    return ServiceContractModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
