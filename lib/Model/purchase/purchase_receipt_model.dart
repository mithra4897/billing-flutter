import '../common/json_model.dart';

class PurchaseReceiptModel implements JsonModel {
  const PurchaseReceiptModel(this.data);

  final Map<String, dynamic> data;

  factory PurchaseReceiptModel.fromJson(Map<String, dynamic> json) {
    return PurchaseReceiptModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
