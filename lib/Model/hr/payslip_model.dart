import '../common/json_model.dart';

class PayslipModel implements JsonModel {
  const PayslipModel(this.data);

  final Map<String, dynamic> data;

  factory PayslipModel.fromJson(Map<String, dynamic> json) {
    return PayslipModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
