import '../common/json_model.dart';

class UserRoleModel implements JsonModel {
  const UserRoleModel(this.data);

  final Map<String, dynamic> data;

  factory UserRoleModel.fromJson(Map<String, dynamic> json) {
    return UserRoleModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
