import '../common/json_model.dart';

class JobworkChargeModel implements JsonModel {
  const JobworkChargeModel(this.data);

  final Map<String, dynamic> data;

  factory JobworkChargeModel.fromJson(Map<String, dynamic> json) {
    return JobworkChargeModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
