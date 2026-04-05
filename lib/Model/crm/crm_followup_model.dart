import '../common/json_model.dart';

class CrmFollowupModel implements JsonModel {
  const CrmFollowupModel(this.data);

  final Map<String, dynamic> data;

  factory CrmFollowupModel.fromJson(Map<String, dynamic> json) {
    return CrmFollowupModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
