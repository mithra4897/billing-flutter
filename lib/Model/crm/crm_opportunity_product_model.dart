import '../common/json_model.dart';

class CrmOpportunityProductModel implements JsonModel {
  const CrmOpportunityProductModel(this.data);

  final Map<String, dynamic> data;

  factory CrmOpportunityProductModel.fromJson(Map<String, dynamic> json) {
    return CrmOpportunityProductModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
