import '../common/json_model.dart';

class BudgetModel implements JsonModel {
  const BudgetModel(this.data);

  final Map<String, dynamic> data;

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
