import '../../screen.dart';

class PayrollLineModel extends JsonModel {
  const PayrollLineModel({
    super.id,
    this.payrollRunId,
    this.employeeId,
    this.grossSalary,
    this.totalDeductions,
    this.netSalary,
    this.workingDays,
    this.presentDays,
    this.leaveDays,
    this.lopDays,
    this.createdAt,
    this.updatedAt,
  });
  final int? payrollRunId;
  final int? employeeId;
  final double? grossSalary;
  final double? totalDeductions;
  final double? netSalary;
  final int? workingDays;
  final int? presentDays;
  final int? leaveDays;
  final double? lopDays;
  final String? createdAt;
  final String? updatedAt;

  factory PayrollLineModel.fromJson(Map<String, dynamic> json) {
    return PayrollLineModel(
      id: ModelValue.nullableInt(json['id']),
      payrollRunId: ModelValue.nullableInt(json['payroll_run_id']),
      employeeId: ModelValue.nullableInt(json['employee_id']),
      grossSalary: ModelValue.nullableDouble(json['gross_salary']),
      totalDeductions: ModelValue.nullableDouble(json['total_deductions']),
      netSalary: ModelValue.nullableDouble(json['net_salary']),
      workingDays: ModelValue.nullableInt(json['working_days']),
      presentDays: ModelValue.nullableInt(json['present_days']),
      leaveDays: ModelValue.nullableInt(json['leave_days']),
      lopDays: ModelValue.nullableDouble(json['lop_days']),
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
    if (grossSalary != null) 'gross_salary': grossSalary,
    if (totalDeductions != null) 'total_deductions': totalDeductions,
    if (netSalary != null) 'net_salary': netSalary,
    if (workingDays != null) 'working_days': workingDays,
    if (presentDays != null) 'present_days': presentDays,
    if (leaveDays != null) 'leave_days': leaveDays,
    if (lopDays != null) 'lop_days': lopDays,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
