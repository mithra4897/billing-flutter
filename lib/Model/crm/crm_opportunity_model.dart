import '../common/json_model.dart';

class CrmOpportunityModel implements JsonModel {
  const CrmOpportunityModel(this.data);

  final Map<String, dynamic> data;

  factory CrmOpportunityModel.fromJson(Map<String, dynamic> json) {
    return CrmOpportunityModel(json);
  }

  @override
  String toString() {
    final name = data['opportunity_name']?.toString().trim() ?? '';
    if (name.isNotEmpty) {
      return name;
    }

    final no = data['enquiry_no']?.toString().trim() ?? '';
    if (no.isNotEmpty) {
      return no;
    }

    return 'New Opportunity';
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
