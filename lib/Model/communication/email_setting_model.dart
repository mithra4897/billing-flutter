import '../common/json_model.dart';

class EmailSettingModel implements JsonModel {
  const EmailSettingModel(this.data);

  final Map<String, dynamic> data;

  factory EmailSettingModel.fromJson(Map<String, dynamic> json) {
    return EmailSettingModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
