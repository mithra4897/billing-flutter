import '../common/json_model.dart';

class PostingRuleModel implements JsonModel {
  const PostingRuleModel(this.data);

  final Map<String, dynamic> data;

  factory PostingRuleModel.fromJson(Map<String, dynamic> json) {
    return PostingRuleModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
