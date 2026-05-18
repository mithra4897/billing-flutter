import '../../screen.dart';

class PayrollRunModel implements JsonModel {
  const PayrollRunModel(this.data);

  final Map<String, dynamic> data;

  factory PayrollRunModel.fromJson(Map<String, dynamic> json) {
    return PayrollRunModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
