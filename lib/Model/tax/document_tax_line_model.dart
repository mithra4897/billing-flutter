import '../common/json_model.dart';

class DocumentTaxLineModel implements JsonModel {
  const DocumentTaxLineModel(this.data);

  final Map<String, dynamic> data;

  factory DocumentTaxLineModel.fromJson(Map<String, dynamic> json) {
    return DocumentTaxLineModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
