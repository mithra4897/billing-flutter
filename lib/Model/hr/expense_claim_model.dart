import '../common/json_model.dart';

class ExpenseClaimModel implements JsonModel {
  const ExpenseClaimModel(this.data);

  final Map<String, dynamic> data;

  factory ExpenseClaimModel.fromJson(Map<String, dynamic> json) {
    return ExpenseClaimModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
