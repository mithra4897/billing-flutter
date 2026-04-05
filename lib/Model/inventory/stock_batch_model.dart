import '../common/json_model.dart';

class StockBatchModel implements JsonModel {
  const StockBatchModel(this.data);

  final Map<String, dynamic> data;

  factory StockBatchModel.fromJson(Map<String, dynamic> json) {
    return StockBatchModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
