import '../common/json_model.dart';

class AssetModel implements JsonModel {
  const AssetModel(this.data);

  final Map<String, dynamic> data;

  factory AssetModel.fromJson(Map<String, dynamic> json) {
    return AssetModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
