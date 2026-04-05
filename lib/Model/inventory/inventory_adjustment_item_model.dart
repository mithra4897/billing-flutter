import '../common/json_model.dart';

class InventoryAdjustmentItemModel implements JsonModel {
  const InventoryAdjustmentItemModel(this.data);

  final Map<String, dynamic> data;

  factory InventoryAdjustmentItemModel.fromJson(Map<String, dynamic> json) {
    return InventoryAdjustmentItemModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
