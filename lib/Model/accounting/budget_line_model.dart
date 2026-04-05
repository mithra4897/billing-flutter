import '../common/json_model.dart';

class BudgetLineModel implements JsonModel {
  const BudgetLineModel(this.data);

  final Map<String, dynamic> data;

  factory BudgetLineModel.fromJson(Map<String, dynamic> json) {
    return BudgetLineModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
