import '../common/json_model.dart';

class PurchaseReturnLineModel implements JsonModel {
  const PurchaseReturnLineModel(this.data);

  final Map<String, dynamic> data;

  factory PurchaseReturnLineModel.fromJson(Map<String, dynamic> json) {
    return PurchaseReturnLineModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
