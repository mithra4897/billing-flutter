import '../../screen.dart';

class ProductionOrderModel implements JsonModel {
  const ProductionOrderModel(this.data);

  final Map<String, dynamic> data;

  factory ProductionOrderModel.fromJson(Map<String, dynamic> json) {
    return ProductionOrderModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
