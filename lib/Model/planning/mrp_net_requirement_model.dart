import '../common/json_model.dart';

class MrpNetRequirementModel implements JsonModel {
  const MrpNetRequirementModel(this.data);

  final Map<String, dynamic> data;

  factory MrpNetRequirementModel.fromJson(Map<String, dynamic> json) {
    return MrpNetRequirementModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
