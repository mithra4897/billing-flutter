import '../common/json_model.dart';

class UserCompaniesSyncRequestModel implements JsonModel {
  const UserCompaniesSyncRequestModel(this.data);

  final Map<String, dynamic> data;

  factory UserCompaniesSyncRequestModel.fromJson(Map<String, dynamic> json) {
    return UserCompaniesSyncRequestModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
