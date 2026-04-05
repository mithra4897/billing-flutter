import '../common/json_model.dart';

class ItemAlternateModel implements JsonModel {
  const ItemAlternateModel(this.data);

  final Map<String, dynamic> data;

  factory ItemAlternateModel.fromJson(Map<String, dynamic> json) {
    return ItemAlternateModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
