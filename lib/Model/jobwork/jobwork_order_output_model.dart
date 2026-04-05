import '../common/json_model.dart';

class JobworkOrderOutputModel implements JsonModel {
  const JobworkOrderOutputModel(this.data);

  final Map<String, dynamic> data;

  factory JobworkOrderOutputModel.fromJson(Map<String, dynamic> json) {
    return JobworkOrderOutputModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
