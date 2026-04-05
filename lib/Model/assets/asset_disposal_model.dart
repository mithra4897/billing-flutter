import '../common/json_model.dart';

class AssetDisposalModel implements JsonModel {
  const AssetDisposalModel(this.data);

  final Map<String, dynamic> data;

  factory AssetDisposalModel.fromJson(Map<String, dynamic> json) {
    return AssetDisposalModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
