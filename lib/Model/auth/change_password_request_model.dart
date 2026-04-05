import '../common/json_model.dart';

class ChangePasswordRequestModel implements JsonModel {
  const ChangePasswordRequestModel(this.data);

  final Map<String, dynamic> data;

  factory ChangePasswordRequestModel.fromJson(Map<String, dynamic> json) {
    return ChangePasswordRequestModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
