import '../common/json_model.dart';

class BomLineModel implements JsonModel {
  const BomLineModel(this.data);

  final Map<String, dynamic> data;

  factory BomLineModel.fromJson(Map<String, dynamic> json) {
    return BomLineModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
