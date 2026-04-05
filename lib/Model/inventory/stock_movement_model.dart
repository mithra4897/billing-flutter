import '../common/json_model.dart';

class StockMovementModel implements JsonModel {
  const StockMovementModel(this.data);

  final Map<String, dynamic> data;

  factory StockMovementModel.fromJson(Map<String, dynamic> json) {
    return StockMovementModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
