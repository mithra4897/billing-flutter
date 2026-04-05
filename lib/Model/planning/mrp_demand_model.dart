import '../common/json_model.dart';

class MrpDemandModel implements JsonModel {
  const MrpDemandModel(this.data);

  final Map<String, dynamic> data;

  factory MrpDemandModel.fromJson(Map<String, dynamic> json) {
    return MrpDemandModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
