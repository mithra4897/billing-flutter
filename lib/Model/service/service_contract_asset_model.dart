import '../common/json_model.dart';

class ServiceContractAssetModel implements JsonModel {
  const ServiceContractAssetModel(this.data);

  final Map<String, dynamic> data;

  factory ServiceContractAssetModel.fromJson(Map<String, dynamic> json) {
    return ServiceContractAssetModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
