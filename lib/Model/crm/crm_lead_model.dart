import '../common/json_model.dart';

class CrmLeadModel implements JsonModel {
  const CrmLeadModel(this.data);

  final Map<String, dynamic> data;

  factory CrmLeadModel.fromJson(Map<String, dynamic> json) {
    return CrmLeadModel(json);
  }

  @override
  String toString() {
    final name = data['lead_name']?.toString().trim() ?? '';
    return name.isNotEmpty ? name : 'New Lead';
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
