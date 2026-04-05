import '../common/json_model.dart';

class PurchasePaymentModel implements JsonModel {
  const PurchasePaymentModel(this.data);

  final Map<String, dynamic> data;

  factory PurchasePaymentModel.fromJson(Map<String, dynamic> json) {
    return PurchasePaymentModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
