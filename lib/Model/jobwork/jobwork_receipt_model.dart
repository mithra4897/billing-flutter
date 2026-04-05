import '../common/json_model.dart';

class JobworkReceiptModel implements JsonModel {
  const JobworkReceiptModel(this.data);

  final Map<String, dynamic> data;

  factory JobworkReceiptModel.fromJson(Map<String, dynamic> json) {
    return JobworkReceiptModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
