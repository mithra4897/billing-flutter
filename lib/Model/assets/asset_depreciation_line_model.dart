import '../common/json_model.dart';

class AssetDepreciationLineModel implements JsonModel {
  const AssetDepreciationLineModel(this.data);

  final Map<String, dynamic> data;

  factory AssetDepreciationLineModel.fromJson(Map<String, dynamic> json) {
    return AssetDepreciationLineModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
