import '../common/json_model.dart';

class SalesReceiptModel implements JsonModel {
  const SalesReceiptModel(this.data);

  final Map<String, dynamic> data;

  factory SalesReceiptModel.fromJson(Map<String, dynamic> json) {
    return SalesReceiptModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
