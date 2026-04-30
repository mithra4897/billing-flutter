import '../common/json_model.dart';

class StockSerialModel implements JsonModel {
  const StockSerialModel(this.data);

  final Map<String, dynamic> data;

  factory StockSerialModel.fromJson(Map<String, dynamic> json) {
    return StockSerialModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);

  @override
  String toString() {
    final no = data['serial_no']?.toString().trim();
    if (no != null && no.isNotEmpty) {
      return no;
    }
    final id = data['id'];
    if (id != null) {
      return 'Serial #$id';
    }
    return 'New stock serial';
  }
}
