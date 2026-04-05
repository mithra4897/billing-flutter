import '../common/json_model.dart';

class MrpSupplyModel implements JsonModel {
  const MrpSupplyModel(this.data);

  final Map<String, dynamic> data;

  factory MrpSupplyModel.fromJson(Map<String, dynamic> json) {
    return MrpSupplyModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
