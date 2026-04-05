import '../common/json_model.dart';

class SalesOrderModel implements JsonModel {
  const SalesOrderModel(this.data);

  final Map<String, dynamic> data;

  factory SalesOrderModel.fromJson(Map<String, dynamic> json) {
    return SalesOrderModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
