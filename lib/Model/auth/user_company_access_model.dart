import '../common/json_model.dart';

class UserCompanyAccessModel implements JsonModel {
  const UserCompanyAccessModel(this.data);

  final Map<String, dynamic> data;

  factory UserCompanyAccessModel.fromJson(Map<String, dynamic> json) {
    return UserCompanyAccessModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
