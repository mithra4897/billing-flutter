import '../common/json_model.dart';

class EmployeeModel implements JsonModel {
  const EmployeeModel(this.data);

  final Map<String, dynamic> data;

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
