import '../common/json_model.dart';

class PurchaseRequisitionLineModel implements JsonModel {
  const PurchaseRequisitionLineModel(this.data);

  final Map<String, dynamic> data;

  factory PurchaseRequisitionLineModel.fromJson(Map<String, dynamic> json) {
    return PurchaseRequisitionLineModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
