import '../common/json_model.dart';

class StockDamageEntryModel implements JsonModel {
  const StockDamageEntryModel(this.data);

  final Map<String, dynamic> data;

  factory StockDamageEntryModel.fromJson(Map<String, dynamic> json) {
    return StockDamageEntryModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);

  @override
  String toString() {
    final no = data['damage_no']?.toString().trim();
    if (no != null && no.isNotEmpty) {
      return no;
    }
    final id = data['id'];
    if (id != null) {
      return 'Damage #$id';
    }
    return 'New stock damage';
  }
}
