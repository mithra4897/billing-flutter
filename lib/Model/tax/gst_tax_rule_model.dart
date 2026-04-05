import '../common/json_model.dart';

class GstTaxRuleModel implements JsonModel {
  const GstTaxRuleModel(this.data);

  final Map<String, dynamic> data;

  factory GstTaxRuleModel.fromJson(Map<String, dynamic> json) {
    return GstTaxRuleModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
