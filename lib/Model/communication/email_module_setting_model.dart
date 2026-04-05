import '../common/json_model.dart';

class EmailModuleSettingModel implements JsonModel {
  const EmailModuleSettingModel(this.data);

  final Map<String, dynamic> data;

  factory EmailModuleSettingModel.fromJson(Map<String, dynamic> json) {
    return EmailModuleSettingModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
