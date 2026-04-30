import '../common/json_model.dart';

class StockTransferModel implements JsonModel {
  const StockTransferModel(this.data);

  final Map<String, dynamic> data;

  factory StockTransferModel.fromJson(Map<String, dynamic> json) {
    return StockTransferModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);

  @override
  String toString() {
    final no = data['transfer_no']?.toString().trim();
    if (no != null && no.isNotEmpty) {
      return no;
    }
    final id = data['id'];
    if (id != null) {
      return 'Transfer #$id';
    }
    return 'New stock transfer';
  }
}
