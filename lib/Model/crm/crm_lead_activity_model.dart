import '../common/json_model.dart';

class CrmLeadActivityModel implements JsonModel {
  const CrmLeadActivityModel(this.data);

  final Map<String, dynamic> data;

  factory CrmLeadActivityModel.fromJson(Map<String, dynamic> json) {
    return CrmLeadActivityModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
