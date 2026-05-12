import '../common/json_model.dart';

class StockBatchModel implements JsonModel {
  const StockBatchModel(this.data);

  final Map<String, dynamic> data;

  factory StockBatchModel.fromJson(Map<String, dynamic> json) {
    return StockBatchModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);

  int? get id => int.tryParse(data['id']?.toString() ?? '');

  String get batchNo => data['batch_no']?.toString().trim() ?? '';

  double get balanceQty {
    final primary = double.tryParse(data['balance_qty']?.toString() ?? '');
    if (primary != null) {
      return primary;
    }
    return double.tryParse(data['qty_available']?.toString() ?? '') ?? 0;
  }

  @override
  String toString() {
    final no = batchNo;
    if (no.isNotEmpty) {
      return no;
    }
    if (id != null) {
      return 'Batch #$id';
    }
    return 'New stock batch';
  }
}
