import '../common/json_model.dart';

class SalesQuotationLineModel implements JsonModel {
  const SalesQuotationLineModel(this.data);

  final Map<String, dynamic> data;

  factory SalesQuotationLineModel.fromJson(Map<String, dynamic> json) {
    return SalesQuotationLineModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
