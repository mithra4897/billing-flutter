import '../../screen.dart';

class EmployeeSalaryComponentModel extends JsonModel {
  const EmployeeSalaryComponentModel({
    super.id,
    this.salaryStructureId,
    this.componentName,
    this.componentType,
    this.componentRole,
    this.amount,
    this.calculationBasis,
    this.percentValue,
    this.contributionRole,
    this.sortOrder,
    this.isGlobal = false,
  });
  final int? salaryStructureId;
  final String? componentName;
  final String? componentType;
  final String? componentRole;
  final double? amount;
  final String? calculationBasis;
  final double? percentValue;
  final String? contributionRole;
  final int? sortOrder;
  final bool isGlobal;

  @override
  String toString() => componentName ?? 'New Salary Component';

  factory EmployeeSalaryComponentModel.fromJson(Map<String, dynamic> json) {
    return EmployeeSalaryComponentModel(
      id: _nullableInt(json['id']),
      salaryStructureId: _nullableInt(json['salary_structure_id']),
      componentName: json['component_name']?.toString(),
      componentType: json['component_type']?.toString(),
      componentRole: json['component_role']?.toString(),
      amount: _double(json['amount']),
      calculationBasis: json['calculation_basis']?.toString(),
      percentValue: _double(json['percent_value']),
      contributionRole: json['contribution_role']?.toString(),
      sortOrder: _nullableInt(json['sort_order']),
      isGlobal: json['is_global'] == true || json['is_global'] == 1,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (salaryStructureId != null) 'salary_structure_id': salaryStructureId,
      if (componentName != null) 'component_name': componentName,
      if (componentType != null) 'component_type': componentType,
      if (componentRole != null) 'component_role': componentRole,
      if (amount != null) 'amount': amount,
      if (calculationBasis != null) 'calculation_basis': calculationBasis,
      if (percentValue != null) 'percent_value': percentValue,
      if (contributionRole != null) 'contribution_role': contributionRole,
      if (sortOrder != null) 'sort_order': sortOrder,
    };
  }

  static int? _nullableInt(dynamic value) =>
      int.tryParse(value?.toString() ?? '');

  static double? _double(dynamic value) =>
      double.tryParse(value?.toString() ?? '');
}
