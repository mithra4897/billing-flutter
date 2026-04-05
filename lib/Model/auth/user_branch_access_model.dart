import '../common/json_model.dart';

class UserBranchAccessModel implements JsonModel {
  const UserBranchAccessModel(this.data);

  final Map<String, dynamic> data;

  factory UserBranchAccessModel.fromJson(Map<String, dynamic> json) {
    return UserBranchAccessModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
