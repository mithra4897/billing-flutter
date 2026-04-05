import '../common/json_model.dart';

class AssetTransferModel implements JsonModel {
  const AssetTransferModel(this.data);

  final Map<String, dynamic> data;

  factory AssetTransferModel.fromJson(Map<String, dynamic> json) {
    return AssetTransferModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
