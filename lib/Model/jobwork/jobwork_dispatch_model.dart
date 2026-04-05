import '../common/json_model.dart';

class JobworkDispatchModel implements JsonModel {
  const JobworkDispatchModel(this.data);

  final Map<String, dynamic> data;

  factory JobworkDispatchModel.fromJson(Map<String, dynamic> json) {
    return JobworkDispatchModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
