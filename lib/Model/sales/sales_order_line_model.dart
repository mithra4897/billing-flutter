import '../common/json_model.dart';

class SalesOrderLineModel implements JsonModel {
  const SalesOrderLineModel(this.data);

  final Map<String, dynamic> data;

  factory SalesOrderLineModel.fromJson(Map<String, dynamic> json) {
    return SalesOrderLineModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
