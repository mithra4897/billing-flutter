import '../common/json_model.dart';

class ProductionOrderOperationModel implements JsonModel {
  const ProductionOrderOperationModel(this.data);

  final Map<String, dynamic> data;

  factory ProductionOrderOperationModel.fromJson(Map<String, dynamic> json) {
    return ProductionOrderOperationModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
