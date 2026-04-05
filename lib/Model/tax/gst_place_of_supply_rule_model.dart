import '../common/json_model.dart';

class GstPlaceOfSupplyRuleModel implements JsonModel {
  const GstPlaceOfSupplyRuleModel(this.data);

  final Map<String, dynamic> data;

  factory GstPlaceOfSupplyRuleModel.fromJson(Map<String, dynamic> json) {
    return GstPlaceOfSupplyRuleModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
