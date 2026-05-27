import '../../screen.dart';

class PayrollLineModel extends JsonModel {
  const PayrollLineModel({
    super.id,
    this.payrollRunId,
    this.employeeId,
    this.employeeName,
    this.employeeCode,
    this.grossSalary,
    this.totalDeductions,
    this.netSalary,
    this.workingDays,
    this.presentDays,
    this.leaveDays,
    this.lopDays,
    this.payslipId,
    this.payslipDate,
    this.createdAt,
    this.updatedAt,
  });
  final int? payrollRunId;
  final int? employeeId;
  final String? employeeName;
  final String? employeeCode;
  final double? grossSalary;
  final double? totalDeductions;
  final double? netSalary;
  final int? workingDays;
  final int? presentDays;
  final int? leaveDays;
  final double? lopDays;
  final int? payslipId;
  final String? payslipDate;
  final String? createdAt;
  final String? updatedAt;

  factory PayrollLineModel.fromJson(Map<String, dynamic> json) {
    final employee = _asMap(json['employee']);
    final payslip = _asMap(json['payslip']);
    return PayrollLineModel(
      id: JsonModel.nullableInt(json['id']),
      payrollRunId: JsonModel.nullableInt(json['payroll_run_id']),
      employeeId: JsonModel.nullableInt(json['employee_id'] ?? employee['id']),
      employeeName: employee['employee_name']?.toString(),
      employeeCode: employee['employee_code']?.toString(),
      grossSalary: JsonModel.nullableDouble(json['gross_salary']),
      totalDeductions: JsonModel.nullableDouble(json['total_deductions']),
      netSalary: JsonModel.nullableDouble(json['net_salary']),
      workingDays: JsonModel.nullableInt(json['working_days']),
      presentDays: JsonModel.nullableInt(json['present_days']),
      leaveDays: JsonModel.nullableInt(json['leave_days']),
      lopDays: JsonModel.nullableDouble(json['lop_days']),
      payslipId: JsonModel.nullableInt(json['payslip_id'] ?? payslip['id']),
      payslipDate:
          payslip['payslip_date']?.toString() ??
          json['payslip_date']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
  @override
  String toString() => 'Payroll Line';

  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (payrollRunId != null) 'payroll_run_id': payrollRunId,
    if (employeeId != null) 'employee_id': employeeId,
    if (employeeName != null) 'employee_name': employeeName,
    if (employeeCode != null) 'employee_code': employeeCode,
    if (grossSalary != null) 'gross_salary': grossSalary,
    if (totalDeductions != null) 'total_deductions': totalDeductions,
    if (netSalary != null) 'net_salary': netSalary,
    if (workingDays != null) 'working_days': workingDays,
    if (presentDays != null) 'present_days': presentDays,
    if (leaveDays != null) 'leave_days': leaveDays,
    if (lopDays != null) 'lop_days': lopDays,
    if (payslipId != null) 'payslip_id': payslipId,
    if (payslipDate != null) 'payslip_date': payslipDate,
    if (employeeName != null || employeeCode != null)
      'employee': <String, dynamic>{
        if (employeeId != null) 'id': employeeId,
        if (employeeName != null) 'employee_name': employeeName,
        if (employeeCode != null) 'employee_code': employeeCode,
      },
    if (payslipId != null || payslipDate != null)
      'payslip': <String, dynamic>{
        if (payslipId != null) 'id': payslipId,
        if (payslipDate != null) 'payslip_date': payslipDate,
      },
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return const <String, dynamic>{};
}
