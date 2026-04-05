import '../common/json_model.dart';

class JobworkReceiptLineModel implements JsonModel {
  const JobworkReceiptLineModel(this.data);

  final Map<String, dynamic> data;

  factory JobworkReceiptLineModel.fromJson(Map<String, dynamic> json) {
    return JobworkReceiptLineModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
