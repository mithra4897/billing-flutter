import '../common/json_model.dart';

class BudgetVsActualModel implements JsonModel {
  const BudgetVsActualModel(this.data);

  final Map<String, dynamic> data;

  factory BudgetVsActualModel.fromJson(Map<String, dynamic> json) {
    return BudgetVsActualModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
