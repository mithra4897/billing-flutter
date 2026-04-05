import '../common/json_model.dart';

class OpeningStockModel implements JsonModel {
  const OpeningStockModel(this.data);

  final Map<String, dynamic> data;

  factory OpeningStockModel.fromJson(Map<String, dynamic> json) {
    return OpeningStockModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
