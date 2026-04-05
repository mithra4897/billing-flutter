import '../common/json_model.dart';

class AssetTransferLineModel implements JsonModel {
  const AssetTransferLineModel(this.data);

  final Map<String, dynamic> data;

  factory AssetTransferLineModel.fromJson(Map<String, dynamic> json) {
    return AssetTransferLineModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
