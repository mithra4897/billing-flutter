import '../common/json_model.dart';

class StockTransferModel implements JsonModel {
  const StockTransferModel(this.data);

  final Map<String, dynamic> data;

  factory StockTransferModel.fromJson(Map<String, dynamic> json) {
    return StockTransferModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
