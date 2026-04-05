import '../common/json_model.dart';

class PhysicalStockCountModel implements JsonModel {
  const PhysicalStockCountModel(this.data);

  final Map<String, dynamic> data;

  factory PhysicalStockCountModel.fromJson(Map<String, dynamic> json) {
    return PhysicalStockCountModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
