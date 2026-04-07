import '../common/json_model.dart';

class EmailModuleSettingModel implements JsonModel {
  const EmailModuleSettingModel(this.data);

  final Map<String, dynamic> data;

  @override
  String toString() =>
      data['module']?.toString() ??
      data['document_type']?.toString() ??
      'New Module Setting';

  factory EmailModuleSettingModel.fromJson(Map<String, dynamic> json) {
    return EmailModuleSettingModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
