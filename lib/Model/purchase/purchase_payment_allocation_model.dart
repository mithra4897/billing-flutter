import '../common/json_model.dart';

class PurchasePaymentAllocationModel implements JsonModel {
  const PurchasePaymentAllocationModel(this.data);

  final Map<String, dynamic> data;

  factory PurchasePaymentAllocationModel.fromJson(Map<String, dynamic> json) {
    return PurchasePaymentAllocationModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
