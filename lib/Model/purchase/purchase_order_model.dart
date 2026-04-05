import '../common/json_model.dart';

class PurchaseOrderModel implements JsonModel {
  const PurchaseOrderModel(this.data);

  final Map<String, dynamic> data;

  factory PurchaseOrderModel.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
