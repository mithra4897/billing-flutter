import '../common/json_model.dart';

class CashSessionModel implements JsonModel {
  const CashSessionModel(this.data);

  final Map<String, dynamic> data;

  factory CashSessionModel.fromJson(Map<String, dynamic> json) {
    return CashSessionModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
