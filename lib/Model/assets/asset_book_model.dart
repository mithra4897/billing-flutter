import '../common/json_model.dart';

class AssetBookModel implements JsonModel {
  const AssetBookModel(this.data);

  final Map<String, dynamic> data;

  factory AssetBookModel.fromJson(Map<String, dynamic> json) {
    return AssetBookModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
