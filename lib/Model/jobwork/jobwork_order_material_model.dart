import '../common/json_model.dart';

class JobworkOrderMaterialModel implements JsonModel {
  const JobworkOrderMaterialModel(this.data);

  final Map<String, dynamic> data;

  factory JobworkOrderMaterialModel.fromJson(Map<String, dynamic> json) {
    return JobworkOrderMaterialModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
