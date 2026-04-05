import '../common/json_model.dart';

class UserRolesSyncRequestModel implements JsonModel {
  const UserRolesSyncRequestModel(this.data);

  final Map<String, dynamic> data;

  factory UserRolesSyncRequestModel.fromJson(Map<String, dynamic> json) {
    return UserRolesSyncRequestModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
