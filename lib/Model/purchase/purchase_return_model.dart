import '../common/json_model.dart';

class PurchaseReturnModel implements JsonModel {
  const PurchaseReturnModel(this.data);

  final Map<String, dynamic> data;

  factory PurchaseReturnModel.fromJson(Map<String, dynamic> json) {
    return PurchaseReturnModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
