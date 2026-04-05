import '../common/json_model.dart';

class AssetCategoryModel implements JsonModel {
  const AssetCategoryModel(this.data);

  final Map<String, dynamic> data;

  factory AssetCategoryModel.fromJson(Map<String, dynamic> json) {
    return AssetCategoryModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
