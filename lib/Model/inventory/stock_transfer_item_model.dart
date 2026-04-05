import '../common/json_model.dart';

class StockTransferItemModel implements JsonModel {
  const StockTransferItemModel(this.data);

  final Map<String, dynamic> data;

  factory StockTransferItemModel.fromJson(Map<String, dynamic> json) {
    return StockTransferItemModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
