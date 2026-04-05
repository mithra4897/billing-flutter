import '../common/json_model.dart';

class LoginHistoryModel implements JsonModel {
  const LoginHistoryModel(this.data);

  final Map<String, dynamic> data;

  factory LoginHistoryModel.fromJson(Map<String, dynamic> json) {
    return LoginHistoryModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
