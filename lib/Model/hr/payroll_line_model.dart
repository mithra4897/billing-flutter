import '../common/json_model.dart';

class PayrollLineModel implements JsonModel {
  const PayrollLineModel(this.data);

  final Map<String, dynamic> data;

  factory PayrollLineModel.fromJson(Map<String, dynamic> json) {
    return PayrollLineModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
