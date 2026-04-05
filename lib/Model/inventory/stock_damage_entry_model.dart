import '../common/json_model.dart';

class StockDamageEntryModel implements JsonModel {
  const StockDamageEntryModel(this.data);

  final Map<String, dynamic> data;

  factory StockDamageEntryModel.fromJson(Map<String, dynamic> json) {
    return StockDamageEntryModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
