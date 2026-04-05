import '../common/json_model.dart';

class ItemPlanningPolicyModel implements JsonModel {
  const ItemPlanningPolicyModel(this.data);

  final Map<String, dynamic> data;

  factory ItemPlanningPolicyModel.fromJson(Map<String, dynamic> json) {
    return ItemPlanningPolicyModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
