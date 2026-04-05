import '../common/json_model.dart';

class InternalStockReceiptLineModel implements JsonModel {
  const InternalStockReceiptLineModel(this.data);

  final Map<String, dynamic> data;

  factory InternalStockReceiptLineModel.fromJson(Map<String, dynamic> json) {
    return InternalStockReceiptLineModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
