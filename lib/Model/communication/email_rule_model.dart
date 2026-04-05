import '../common/json_model.dart';

class EmailRuleModel implements JsonModel {
  const EmailRuleModel(this.data);

  final Map<String, dynamic> data;

  factory EmailRuleModel.fromJson(Map<String, dynamic> json) {
    return EmailRuleModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
