import '../common/json_model.dart';

class AssetDowntimeLogModel implements JsonModel {
  const AssetDowntimeLogModel(this.data);

  final Map<String, dynamic> data;

  factory AssetDowntimeLogModel.fromJson(Map<String, dynamic> json) {
    return AssetDowntimeLogModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
