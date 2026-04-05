import '../common/json_model.dart';

class StockDamageLineModel implements JsonModel {
  const StockDamageLineModel(this.data);

  final Map<String, dynamic> data;

  factory StockDamageLineModel.fromJson(Map<String, dynamic> json) {
    return StockDamageLineModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
