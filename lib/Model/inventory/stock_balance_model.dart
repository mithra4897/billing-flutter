import '../common/json_model.dart';

class StockBalanceModel implements JsonModel {
  const StockBalanceModel(this.data);

  final Map<String, dynamic> data;

  factory StockBalanceModel.fromJson(Map<String, dynamic> json) {
    return StockBalanceModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
