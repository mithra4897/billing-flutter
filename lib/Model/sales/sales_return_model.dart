import '../common/json_model.dart';

class SalesReturnModel implements JsonModel {
  const SalesReturnModel(this.data);

  final Map<String, dynamic> data;

  factory SalesReturnModel.fromJson(Map<String, dynamic> json) {
    return SalesReturnModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
