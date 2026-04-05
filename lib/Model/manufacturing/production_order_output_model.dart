import '../common/json_model.dart';

class ProductionOrderOutputModel implements JsonModel {
  const ProductionOrderOutputModel(this.data);

  final Map<String, dynamic> data;

  factory ProductionOrderOutputModel.fromJson(Map<String, dynamic> json) {
    return ProductionOrderOutputModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
