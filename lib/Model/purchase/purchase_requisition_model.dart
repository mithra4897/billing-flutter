import '../common/json_model.dart';

class PurchaseRequisitionModel implements JsonModel {
  const PurchaseRequisitionModel(this.data);

  final Map<String, dynamic> data;

  factory PurchaseRequisitionModel.fromJson(Map<String, dynamic> json) {
    return PurchaseRequisitionModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
