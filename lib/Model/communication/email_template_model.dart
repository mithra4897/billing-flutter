import '../common/json_model.dart';

class EmailTemplateModel implements JsonModel {
  const EmailTemplateModel(this.data);

  final Map<String, dynamic> data;

  @override
  String toString() =>
      data['template_name']?.toString() ??
      data['template_code']?.toString() ??
      'New Template';

  factory EmailTemplateModel.fromJson(Map<String, dynamic> json) {
    return EmailTemplateModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
