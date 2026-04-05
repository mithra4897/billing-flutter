import '../common/json_model.dart';

class ProductionReceiptLineModel implements JsonModel {
  const ProductionReceiptLineModel(this.data);

  final Map<String, dynamic> data;

  factory ProductionReceiptLineModel.fromJson(Map<String, dynamic> json) {
    return ProductionReceiptLineModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
