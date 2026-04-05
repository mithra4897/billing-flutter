import '../common/json_model.dart';

class EmailTemplateModel implements JsonModel {
  const EmailTemplateModel(this.data);

  final Map<String, dynamic> data;

  factory EmailTemplateModel.fromJson(Map<String, dynamic> json) {
    return EmailTemplateModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
