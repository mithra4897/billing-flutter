import '../common/json_model.dart';

class CrmStageModel implements JsonModel {
  const CrmStageModel(this.data);

  final Map<String, dynamic> data;

  factory CrmStageModel.fromJson(Map<String, dynamic> json) {
    return CrmStageModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
