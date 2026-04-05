import '../common/json_model.dart';

class ProductionOrderMaterialModel implements JsonModel {
  const ProductionOrderMaterialModel(this.data);

  final Map<String, dynamic> data;

  factory ProductionOrderMaterialModel.fromJson(Map<String, dynamic> json) {
    return ProductionOrderMaterialModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
