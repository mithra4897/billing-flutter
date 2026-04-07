import '../common/json_model.dart';

class EmailRuleModel implements JsonModel {
  const EmailRuleModel(this.data);

  final Map<String, dynamic> data;

  @override
  String toString() =>
      data['rule_name']?.toString() ??
      data['rule_code']?.toString() ??
      'New Rule';

  factory EmailRuleModel.fromJson(Map<String, dynamic> json) {
    return EmailRuleModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
