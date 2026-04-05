import '../common/json_model.dart';

class PartyCreditLimitModel implements JsonModel {
  const PartyCreditLimitModel(this.data);

  final Map<String, dynamic> data;

  factory PartyCreditLimitModel.fromJson(Map<String, dynamic> json) {
    return PartyCreditLimitModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
