import '../../screen.dart';

class PayrollRunModel extends JsonModel {
  const PayrollRunModel({
    super.id,
    this.companyId,
    this.payrollMonth,
    this.payrollYear,
    this.runDate,
    this.useAttendance,
    this.status,
    this.voucherId,
    this.createdBy,
    this.creatorDisplayName,
    this.creatorUsername,
    this.voucherNo,
    this.voucherDate,
    this.linesCount,
    this.lines = const <PayrollLineModel>[],
    this.payrollPreview,
    this.createdAt,
    this.updatedAt,
  });
  final int? companyId;
  final String? payrollMonth;
  final String? payrollYear;
  final String? runDate;
  final bool? useAttendance;
  final String? status;
  final int? voucherId;
  final int? createdBy;
  final String? creatorDisplayName;
  final String? creatorUsername;
  final String? voucherNo;
  final String? voucherDate;
  final int? linesCount;
  final List<PayrollLineModel> lines;
  final PayrollPreviewModel? payrollPreview;
  final String? createdAt;
  final String? updatedAt;

  String get periodLabel {
    final year = payrollYear?.trim() ?? '';
    final month = payrollMonth?.trim() ?? '';
    if (year.isEmpty || month.isEmpty) {
      return '';
    }
    return '$year-${month.padLeft(2, '0')}';
  }

  factory PayrollRunModel.fromJson(Map<String, dynamic> json) {
    final creator = _asMap(json['creator']);
    final voucher = _asMap(json['voucher']);
    final lines = _asList(
      json['lines'],
    ).map((item) => PayrollLineModel.fromJson(item)).toList(growable: false);
    return PayrollRunModel(
      id: JsonModel.nullableInt(json['id']),
      companyId: JsonModel.nullableInt(json['company_id']),
      payrollMonth: json['payroll_month']?.toString(),
      payrollYear: json['payroll_year']?.toString(),
      runDate: json['run_date']?.toString(),
      useAttendance: json['use_attendance'] == null
          ? null
          : JsonModel.boolOf(json['use_attendance']),
      status: json['status']?.toString(),
      voucherId: JsonModel.nullableInt(json['voucher_id'] ?? voucher['id']),
      createdBy: JsonModel.nullableInt(json['created_by']),
      creatorDisplayName: creator['display_name']?.toString(),
      creatorUsername: creator['username']?.toString(),
      voucherNo: voucher['voucher_no']?.toString(),
      voucherDate: voucher['voucher_date']?.toString(),
      linesCount: JsonModel.nullableInt(json['lines_count']) ?? lines.length,
      lines: lines,
      payrollPreview: json['payroll_preview'] is Map
          ? PayrollPreviewModel.fromJson(_asMap(json['payroll_preview']))
          : null,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
  @override
  String toString() => JsonModel.combineValues([
    periodLabel,
    runDate,
  ], defaultValue: 'Payroll Run');

  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (companyId != null) 'company_id': companyId,
    if (payrollMonth != null) 'payroll_month': payrollMonth,
    if (payrollYear != null) 'payroll_year': payrollYear,
    if (runDate != null) 'run_date': runDate,
    if (useAttendance != null) 'use_attendance': useAttendance,
    if (status != null) 'status': status,
    if (voucherId != null) 'voucher_id': voucherId,
    if (createdBy != null) 'created_by': createdBy,
    if (creatorDisplayName != null || creatorUsername != null)
      'creator': <String, dynamic>{
        if (createdBy != null) 'id': createdBy,
        if (creatorDisplayName != null) 'display_name': creatorDisplayName,
        if (creatorUsername != null) 'username': creatorUsername,
      },
    if (voucherNo != null || voucherDate != null)
      'voucher': <String, dynamic>{
        if (voucherId != null) 'id': voucherId,
        if (voucherNo != null) 'voucher_no': voucherNo,
        if (voucherDate != null) 'voucher_date': voucherDate,
      },
    if (linesCount != null) 'lines_count': linesCount,
    if (lines.isNotEmpty)
      'lines': lines.map((item) => item.toJson()).toList(growable: false),
    if (payrollPreview != null) 'payroll_preview': payrollPreview!.toJson(),
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}

class PayrollPreviewModel extends JsonModel {
  const PayrollPreviewModel({
    this.eligibleCount = 0,
    this.excludedCount = 0,
    this.employees = const <PayrollEmployeePreviewModel>[],
  });

  final int eligibleCount;
  final int excludedCount;
  final List<PayrollEmployeePreviewModel> employees;

  factory PayrollPreviewModel.fromJson(Map<String, dynamic> json) {
    return PayrollPreviewModel(
      eligibleCount: JsonModel.nullableInt(json['eligible_count']) ?? 0,
      excludedCount: JsonModel.nullableInt(json['excluded_count']) ?? 0,
      employees: _asList(
        json['employees'],
      ).map(PayrollEmployeePreviewModel.fromJson).toList(growable: false),
    );
  }

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'eligible_count': eligibleCount,
    'excluded_count': excludedCount,
    'employees': employees.map((item) => item.toJson()).toList(growable: false),
  };
}

class PayrollEmployeePreviewModel extends JsonModel {
  const PayrollEmployeePreviewModel({
    this.employeeId,
    this.employeeCode,
    this.employeeName,
    this.eligible = false,
    this.reason,
    this.salaryStructureId,
    this.grossSalary,
    this.workingDays,
    this.presentDays,
    this.leaveDays,
    this.paidDays,
    this.lopDays,
  });

  final int? employeeId;
  final String? employeeCode;
  final String? employeeName;
  final bool eligible;
  final String? reason;
  final int? salaryStructureId;
  final double? grossSalary;
  final int? workingDays;
  final double? presentDays;
  final double? leaveDays;
  final double? paidDays;
  final double? lopDays;

  factory PayrollEmployeePreviewModel.fromJson(Map<String, dynamic> json) {
    return PayrollEmployeePreviewModel(
      employeeId: JsonModel.nullableInt(json['employee_id']),
      employeeCode: json['employee_code']?.toString(),
      employeeName: json['employee_name']?.toString(),
      eligible: JsonModel.boolOf(json['eligible']),
      reason: json['reason']?.toString(),
      salaryStructureId: JsonModel.nullableInt(json['salary_structure_id']),
      grossSalary: JsonModel.nullableDouble(json['gross_salary']),
      workingDays: JsonModel.nullableInt(json['working_days']),
      presentDays: JsonModel.nullableDouble(json['present_days']),
      leaveDays: JsonModel.nullableDouble(json['leave_days']),
      paidDays: JsonModel.nullableDouble(json['paid_days']),
      lopDays: JsonModel.nullableDouble(json['lop_days']),
    );
  }

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    if (employeeId != null) 'employee_id': employeeId,
    if (employeeCode != null) 'employee_code': employeeCode,
    if (employeeName != null) 'employee_name': employeeName,
    'eligible': eligible,
    if (reason != null) 'reason': reason,
    if (salaryStructureId != null) 'salary_structure_id': salaryStructureId,
    if (grossSalary != null) 'gross_salary': grossSalary,
    if (workingDays != null) 'working_days': workingDays,
    if (presentDays != null) 'present_days': presentDays,
    if (leaveDays != null) 'leave_days': leaveDays,
    if (paidDays != null) 'paid_days': paidDays,
    if (lopDays != null) 'lop_days': lopDays,
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

List<Map<String, dynamic>> _asList(dynamic value) {
  if (value is List<Map<String, dynamic>>) {
    return value;
  }
  if (value is List) {
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }
  return const <Map<String, dynamic>>[];
}
