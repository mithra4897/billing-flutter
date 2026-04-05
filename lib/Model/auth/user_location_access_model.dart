import '../common/json_model.dart';

class UserLocationAccessModel implements JsonModel {
  const UserLocationAccessModel(this.data);

  final Map<String, dynamic> data;

  factory UserLocationAccessModel.fromJson(Map<String, dynamic> json) {
    return UserLocationAccessModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
