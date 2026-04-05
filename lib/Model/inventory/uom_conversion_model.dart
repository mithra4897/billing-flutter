import '../common/json_model.dart';

class UomConversionModel implements JsonModel {
  const UomConversionModel(this.data);

  final Map<String, dynamic> data;

  factory UomConversionModel.fromJson(Map<String, dynamic> json) {
    return UomConversionModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
