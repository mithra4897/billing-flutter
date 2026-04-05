import '../common/json_model.dart';

class InventoryAdjustmentModel implements JsonModel {
  const InventoryAdjustmentModel(this.data);

  final Map<String, dynamic> data;

  factory InventoryAdjustmentModel.fromJson(Map<String, dynamic> json) {
    return InventoryAdjustmentModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
