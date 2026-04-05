import '../common/json_model.dart';

class SalesReturnLineModel implements JsonModel {
  const SalesReturnLineModel(this.data);

  final Map<String, dynamic> data;

  factory SalesReturnLineModel.fromJson(Map<String, dynamic> json) {
    return SalesReturnLineModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
