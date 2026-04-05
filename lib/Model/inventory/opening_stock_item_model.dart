import '../common/json_model.dart';

class OpeningStockItemModel implements JsonModel {
  const OpeningStockItemModel(this.data);

  final Map<String, dynamic> data;

  factory OpeningStockItemModel.fromJson(Map<String, dynamic> json) {
    return OpeningStockItemModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
