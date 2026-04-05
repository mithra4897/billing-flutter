import '../common/json_model.dart';

class BankReconciliationModel implements JsonModel {
  const BankReconciliationModel(this.data);

  final Map<String, dynamic> data;

  factory BankReconciliationModel.fromJson(Map<String, dynamic> json) {
    return BankReconciliationModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
