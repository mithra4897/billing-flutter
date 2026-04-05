import '../common/json_model.dart';

class JobworkChargeLineModel implements JsonModel {
  const JobworkChargeLineModel(this.data);

  final Map<String, dynamic> data;

  factory JobworkChargeLineModel.fromJson(Map<String, dynamic> json) {
    return JobworkChargeLineModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
