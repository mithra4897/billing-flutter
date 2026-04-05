import '../common/json_model.dart';

class PostingRuleGroupModel implements JsonModel {
  const PostingRuleGroupModel(this.data);

  final Map<String, dynamic> data;

  factory PostingRuleGroupModel.fromJson(Map<String, dynamic> json) {
    return PostingRuleGroupModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
