import '../common/json_model.dart';

class PhysicalStockCountLineModel implements JsonModel {
  const PhysicalStockCountLineModel(this.data);

  final Map<String, dynamic> data;

  factory PhysicalStockCountLineModel.fromJson(Map<String, dynamic> json) {
    return PhysicalStockCountLineModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
