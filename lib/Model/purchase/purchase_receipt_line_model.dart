import '../common/json_model.dart';

class PurchaseReceiptLineModel implements JsonModel {
  const PurchaseReceiptLineModel(this.data);

  final Map<String, dynamic> data;

  factory PurchaseReceiptLineModel.fromJson(Map<String, dynamic> json) {
    return PurchaseReceiptLineModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
