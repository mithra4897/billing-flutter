import '../../screen.dart';

class PayrollLineModel extends JsonModel {
  const PayrollLineModel({
    super.id,
    this.payrollRunId,
    this.employeeId,
    this.employeeName,
    this.employeeCode,
    this.salaryStructureId,
    this.monthlyGrossSalary,
    this.basicSalary,
    this.ctcMonthly,
    this.grossSalary,
    this.totalDeductions,
    this.netSalary,
    this.workingDays,
    this.presentDays,
    this.leaveDays,
    this.paidDays,
    this.attendanceLopDays,
    this.leaveLopDays,
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
  final int? salaryStructureId;
  final double? monthlyGrossSalary;
  final double? basicSalary;
  final double? ctcMonthly;
  final double? grossSalary;
  final double? totalDeductions;
  final double? netSalary;
  final int? workingDays;
  final double? presentDays;
  final double? leaveDays;
  final double? paidDays;
  final double? attendanceLopDays;
  final double? leaveLopDays;
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
      salaryStructureId: JsonModel.nullableInt(json['salary_structure_id']),
      monthlyGrossSalary: JsonModel.nullableDouble(
        json['monthly_gross_salary'],
      ),
      basicSalary: JsonModel.nullableDouble(json['basic_salary']),
      ctcMonthly: JsonModel.nullableDouble(json['ctc_monthly']),
      grossSalary: JsonModel.nullableDouble(json['gross_salary']),
      totalDeductions: JsonModel.nullableDouble(json['total_deductions']),
      netSalary: JsonModel.nullableDouble(json['net_salary']),
      workingDays: JsonModel.nullableInt(json['working_days']),
      presentDays: JsonModel.nullableDouble(json['present_days']),
      leaveDays: JsonModel.nullableDouble(json['leave_days']),
      paidDays: JsonModel.nullableDouble(json['paid_days']),
      attendanceLopDays: JsonModel.nullableDouble(json['attendance_lop_days']),
      leaveLopDays: JsonModel.nullableDouble(json['leave_lop_days']),
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
    if (salaryStructureId != null) 'salary_structure_id': salaryStructureId,
    if (monthlyGrossSalary != null) 'monthly_gross_salary': monthlyGrossSalary,
    if (basicSalary != null) 'basic_salary': basicSalary,
    if (ctcMonthly != null) 'ctc_monthly': ctcMonthly,
    if (grossSalary != null) 'gross_salary': grossSalary,
    if (totalDeductions != null) 'total_deductions': totalDeductions,
    if (netSalary != null) 'net_salary': netSalary,
    if (workingDays != null) 'working_days': workingDays,
    if (presentDays != null) 'present_days': presentDays,
    if (leaveDays != null) 'leave_days': leaveDays,
    if (paidDays != null) 'paid_days': paidDays,
    if (attendanceLopDays != null) 'attendance_lop_days': attendanceLopDays,
    if (leaveLopDays != null) 'leave_lop_days': leaveLopDays,
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
