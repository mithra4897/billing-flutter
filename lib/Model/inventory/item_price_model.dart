import '../common/json_model.dart';

class ItemPriceModel implements JsonModel {
  const ItemPriceModel(this.data);

  final Map<String, dynamic> data;

  factory ItemPriceModel.fromJson(Map<String, dynamic> json) {
    return ItemPriceModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
