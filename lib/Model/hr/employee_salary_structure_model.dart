import '../common/json_model.dart';

class EmployeeSalaryStructureModel implements JsonModel {
  const EmployeeSalaryStructureModel(this.data);

  final Map<String, dynamic> data;

  factory EmployeeSalaryStructureModel.fromJson(Map<String, dynamic> json) {
    return EmployeeSalaryStructureModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
