import '../common/json_model.dart';

class ProductionMaterialIssueLineModel implements JsonModel {
  const ProductionMaterialIssueLineModel(this.data);

  final Map<String, dynamic> data;

  factory ProductionMaterialIssueLineModel.fromJson(Map<String, dynamic> json) {
    return ProductionMaterialIssueLineModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
