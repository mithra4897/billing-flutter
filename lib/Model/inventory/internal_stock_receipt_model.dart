import '../common/json_model.dart';

class InternalStockReceiptModel implements JsonModel {
  const InternalStockReceiptModel(this.data);

  final Map<String, dynamic> data;

  factory InternalStockReceiptModel.fromJson(Map<String, dynamic> json) {
    return InternalStockReceiptModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);

  @override
  String toString() {
    final no = data['receipt_no']?.toString().trim();
    if (no != null && no.isNotEmpty) {
      return no;
    }
    final id = data['id'];
    if (id != null) {
      return 'Receipt #$id';
    }
    return 'New internal receipt';
  }
}
