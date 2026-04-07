import '../common/json_model.dart';

class EmailMessageModel implements JsonModel {
  const EmailMessageModel(this.data);

  final Map<String, dynamic> data;

  @override
  String toString() =>
      data['subject']?.toString() ??
      data['module']?.toString() ??
      'Email Message';

  factory EmailMessageModel.fromJson(Map<String, dynamic> json) {
    return EmailMessageModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
