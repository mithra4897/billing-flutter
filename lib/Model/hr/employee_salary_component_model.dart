import '../common/json_model.dart';

class EmployeeSalaryComponentModel implements JsonModel {
  const EmployeeSalaryComponentModel({
    this.id,
    this.salaryStructureId,
    this.componentName,
    this.componentType,
    this.amount,
    this.calculationBasis,
    this.percentValue,
    this.contributionRole,
    this.raw,
  });

  final int? id;
  final int? salaryStructureId;
  final String? componentName;
  final String? componentType;
  final double? amount;
  final String? calculationBasis;
  final double? percentValue;
  final String? contributionRole;
  final Map<String, dynamic>? raw;

  @override
  String toString() => componentName ?? 'New Salary Component';

  factory EmployeeSalaryComponentModel.fromJson(Map<String, dynamic> json) {
    return EmployeeSalaryComponentModel(
      id: _nullableInt(json['id']),
      salaryStructureId: _nullableInt(json['salary_structure_id']),
      componentName: json['component_name']?.toString(),
      componentType: json['component_type']?.toString(),
      amount: _double(json['amount']),
      calculationBasis: json['calculation_basis']?.toString(),
      percentValue: _double(json['percent_value']),
      contributionRole: json['contribution_role']?.toString(),
      raw: json,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (salaryStructureId != null) 'salary_structure_id': salaryStructureId,
      if (componentName != null) 'component_name': componentName,
      if (componentType != null) 'component_type': componentType,
      if (amount != null) 'amount': amount,
      if (calculationBasis != null) 'calculation_basis': calculationBasis,
      if (percentValue != null) 'percent_value': percentValue,
      if (contributionRole != null) 'contribution_role': contributionRole,
    };
  }

  static int? _nullableInt(dynamic value) =>
      int.tryParse(value?.toString() ?? '');

  static double? _double(dynamic value) =>
      double.tryParse(value?.toString() ?? '');
}
