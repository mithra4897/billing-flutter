import '../common/json_model.dart';

class StockMovementModel implements JsonModel {
  const StockMovementModel(this.data);

  final Map<String, dynamic> data;

  factory StockMovementModel.fromJson(Map<String, dynamic> json) {
    return StockMovementModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);

  @override
  String toString() {
    final refNo = data['reference_no']?.toString().trim();
    if (refNo != null && refNo.isNotEmpty) {
      return refNo;
    }
    final id = data['id'];
    if (id != null) {
      return 'Movement #$id';
    }
    return 'New stock movement';
  }
}
