import '../common/json_model.dart';

class ExpenseClaimLineModel implements JsonModel {
  const ExpenseClaimLineModel(this.data);

  final Map<String, dynamic> data;

  factory ExpenseClaimLineModel.fromJson(Map<String, dynamic> json) {
    return ExpenseClaimLineModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
