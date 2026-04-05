import '../common/json_model.dart';

class EmployeeSalaryComponentModel implements JsonModel {
  const EmployeeSalaryComponentModel(this.data);

  final Map<String, dynamic> data;

  factory EmployeeSalaryComponentModel.fromJson(Map<String, dynamic> json) {
    return EmployeeSalaryComponentModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
