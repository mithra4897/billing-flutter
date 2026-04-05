import '../common/json_model.dart';

class JobworkDispatchLineModel implements JsonModel {
  const JobworkDispatchLineModel(this.data);

  final Map<String, dynamic> data;

  factory JobworkDispatchLineModel.fromJson(Map<String, dynamic> json) {
    return JobworkDispatchLineModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
