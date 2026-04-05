import '../common/json_model.dart';

class ProductionReceiptModel implements JsonModel {
  const ProductionReceiptModel(this.data);

  final Map<String, dynamic> data;

  factory ProductionReceiptModel.fromJson(Map<String, dynamic> json) {
    return ProductionReceiptModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
