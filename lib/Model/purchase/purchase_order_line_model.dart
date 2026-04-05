import '../common/json_model.dart';

class PurchaseOrderLineModel implements JsonModel {
  const PurchaseOrderLineModel(this.data);

  final Map<String, dynamic> data;

  factory PurchaseOrderLineModel.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderLineModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
