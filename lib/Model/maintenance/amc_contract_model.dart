import '../common/json_model.dart';

class AmcContractModel implements JsonModel {
  const AmcContractModel(this.data);

  final Map<String, dynamic> data;

  factory AmcContractModel.fromJson(Map<String, dynamic> json) {
    return AmcContractModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
