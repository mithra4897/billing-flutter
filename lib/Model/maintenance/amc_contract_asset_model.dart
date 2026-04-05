import '../common/json_model.dart';

class AmcContractAssetModel implements JsonModel {
  const AmcContractAssetModel(this.data);

  final Map<String, dynamic> data;

  factory AmcContractAssetModel.fromJson(Map<String, dynamic> json) {
    return AmcContractAssetModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
