import '../common/json_model.dart';
import 'employee_salary_component_model.dart';

class EmployeeSalaryStructureModel implements JsonModel {
  const EmployeeSalaryStructureModel({
    this.id,
    this.employeeId,
    this.effectiveFrom,
    this.basicSalary,
    this.grossSalary,
    this.netSalary,
    this.ctcMonthly,
    this.isActive = true,
    this.components = const <EmployeeSalaryComponentModel>[],
    this.raw,
  });

  final int? id;
  final int? employeeId;
  final String? effectiveFrom;
  final double? basicSalary;
  final double? grossSalary;
  final double? netSalary;
  final double? ctcMonthly;
  final bool isActive;
  final List<EmployeeSalaryComponentModel> components;
  final Map<String, dynamic>? raw;

  @override
  String toString() => effectiveFrom ?? 'New Salary Structure';

  factory EmployeeSalaryStructureModel.fromJson(Map<String, dynamic> json) {
    final components = _asList(json['components'])
        .map((item) => EmployeeSalaryComponentModel.fromJson(item))
        .toList(growable: false);
    return EmployeeSalaryStructureModel(
      id: _nullableInt(json['id']),
      employeeId: _nullableInt(json['employee_id']),
      effectiveFrom: _dateString(json['effective_from']),
      basicSalary: _double(json['basic_salary']),
      grossSalary: _double(json['gross_salary']),
      netSalary: _double(json['net_salary']),
      ctcMonthly: _double(json['ctc_monthly'] ?? json['ctcMonthly']),
      isActive: _bool(json['is_active'], fallback: true),
      components: components,
      raw: json,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (employeeId != null) 'employee_id': employeeId,
      if (effectiveFrom != null) 'effective_from': effectiveFrom,
      if (basicSalary != null) 'basic_salary': basicSalary,
      if (grossSalary != null) 'gross_salary': grossSalary,
      if (netSalary != null) 'net_salary': netSalary,
      if (ctcMonthly != null) 'ctc_monthly': ctcMonthly,
      'is_active': isActive,
      'components': components.map((item) => item.toJson()).toList(),
    };
  }

  EmployeeSalaryStructureModel copyWith({
    int? id,
    int? employeeId,
    String? effectiveFrom,
    double? basicSalary,
    double? grossSalary,
    double? netSalary,
    double? ctcMonthly,
    bool? isActive,
    List<EmployeeSalaryComponentModel>? components,
  }) {
    return EmployeeSalaryStructureModel(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      effectiveFrom: effectiveFrom ?? this.effectiveFrom,
      basicSalary: basicSalary ?? this.basicSalary,
      grossSalary: grossSalary ?? this.grossSalary,
      netSalary: netSalary ?? this.netSalary,
      ctcMonthly: ctcMonthly ?? this.ctcMonthly,
      isActive: isActive ?? this.isActive,
      components: components ?? this.components,
      raw: raw,
    );
  }

  static int? _nullableInt(dynamic value) =>
      int.tryParse(value?.toString() ?? '');

  static double? _double(dynamic value) =>
      double.tryParse(value?.toString() ?? '');

  static bool _bool(dynamic value, {bool fallback = false}) {
    if (value == null) return fallback;
    return value == true || value == 1 || value.toString() == '1';
  }

  static String? _dateString(dynamic value) =>
      value?.toString().split('T').first.split(' ').first;

  static List<Map<String, dynamic>> _asList(dynamic value) {
    if (value is List) {
      return value.whereType<Map<String, dynamic>>().toList(growable: false);
    }
    return const <Map<String, dynamic>>[];
  }
}
