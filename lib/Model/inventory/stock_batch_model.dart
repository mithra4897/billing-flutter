import '../common/json_model.dart';

class StockBatchModel implements JsonModel {
  const StockBatchModel(this.data);

  final Map<String, dynamic> data;

  factory StockBatchModel.fromJson(Map<String, dynamic> json) {
    return StockBatchModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);

  @override
  String toString() {
    final no = data['batch_no']?.toString().trim();
    if (no != null && no.isNotEmpty) {
      return no;
    }
    final id = data['id'];
    if (id != null) {
      return 'Batch #$id';
    }
    return 'New stock batch';
  }
}
