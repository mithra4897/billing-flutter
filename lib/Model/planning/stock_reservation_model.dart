import '../common/json_model.dart';

class StockReservationModel implements JsonModel {
  const StockReservationModel(this.data);

  final Map<String, dynamic> data;

  factory StockReservationModel.fromJson(Map<String, dynamic> json) {
    return StockReservationModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
