import '../common/json_model.dart';

class ProductionMaterialIssueModel implements JsonModel {
  const ProductionMaterialIssueModel(this.data);

  final Map<String, dynamic> data;

  factory ProductionMaterialIssueModel.fromJson(Map<String, dynamic> json) {
    return ProductionMaterialIssueModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
