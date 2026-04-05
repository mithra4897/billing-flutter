import '../common/json_model.dart';

class UserLocationsSyncRequestModel implements JsonModel {
  const UserLocationsSyncRequestModel(this.data);

  final Map<String, dynamic> data;

  factory UserLocationsSyncRequestModel.fromJson(Map<String, dynamic> json) {
    return UserLocationsSyncRequestModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
