import '../common/json_model.dart';

class DepartmentModel implements JsonModel {
  const DepartmentModel(this.data);

  final Map<String, dynamic> data;

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
