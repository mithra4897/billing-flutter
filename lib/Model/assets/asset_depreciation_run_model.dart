import '../common/json_model.dart';

class AssetDepreciationRunModel implements JsonModel {
  const AssetDepreciationRunModel(this.data);

  final Map<String, dynamic> data;

  factory AssetDepreciationRunModel.fromJson(Map<String, dynamic> json) {
    return AssetDepreciationRunModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
