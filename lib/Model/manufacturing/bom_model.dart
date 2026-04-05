import '../common/json_model.dart';

class BomModel implements JsonModel {
  const BomModel(this.data);

  final Map<String, dynamic> data;

  factory BomModel.fromJson(Map<String, dynamic> json) {
    return BomModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
