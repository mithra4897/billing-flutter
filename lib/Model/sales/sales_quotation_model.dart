import '../common/json_model.dart';

class SalesQuotationModel implements JsonModel {
  const SalesQuotationModel(this.data);

  final Map<String, dynamic> data;

  factory SalesQuotationModel.fromJson(Map<String, dynamic> json) {
    return SalesQuotationModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
