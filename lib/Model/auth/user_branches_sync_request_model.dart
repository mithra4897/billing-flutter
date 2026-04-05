import '../common/json_model.dart';

class UserBranchesSyncRequestModel implements JsonModel {
  const UserBranchesSyncRequestModel(this.data);

  final Map<String, dynamic> data;

  factory UserBranchesSyncRequestModel.fromJson(Map<String, dynamic> json) {
    return UserBranchesSyncRequestModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
