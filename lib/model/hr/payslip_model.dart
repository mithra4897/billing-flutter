import '../../screen.dart';

class PayslipModel extends JsonModel {
  const PayslipModel({
    super.id,
    this.payslipNo,
    this.payrollLineId,
    this.payslipDate,
    this.generatedBy,
    this.generatorDisplayName,
    this.generatorUsername,
    this.employeeId,
    this.employeeName,
    this.employeeCode,
    this.payrollRunId,
    this.payrollMonth,
    this.payrollYear,
    this.runDate,
    this.workingDays,
    this.presentDays,
    this.leaveDays,
    this.paidDays,
    this.lopDays,
    this.basicSalary,
    this.grossSalary,
    this.totalDeductions,
    this.ctcMonthly,
    this.netSalary,
    this.company,
    this.employeeProfile,
    this.earnings = const <PayslipBreakupLineModel>[],
    this.deductions = const <PayslipBreakupLineModel>[],
    this.remarks,
    this.createdAt,
    this.updatedAt,
  });

  final String? payslipNo;
  final int? payrollLineId;
  final String? payslipDate;
  final int? generatedBy;
  final String? generatorDisplayName;
  final String? generatorUsername;
  final int? employeeId;
  final String? employeeName;
  final String? employeeCode;
  final int? payrollRunId;
  final String? payrollMonth;
  final String? payrollYear;
  final String? runDate;
  final int? workingDays;
  final int? presentDays;
  final int? leaveDays;
  final double? paidDays;
  final double? lopDays;
  final double? basicSalary;
  final double? grossSalary;
  final double? totalDeductions;
  final double? ctcMonthly;
  final double? netSalary;
  final PayslipCompanyModel? company;
  final PayslipEmployeeProfileModel? employeeProfile;
  final List<PayslipBreakupLineModel> earnings;
  final List<PayslipBreakupLineModel> deductions;
  final String? remarks;
  final String? createdAt;
  final String? updatedAt;

  String get payrollPeriodLabel {
    final year = payrollYear?.trim() ?? '';
    final month = payrollMonth?.trim() ?? '';
    if (year.isEmpty || month.isEmpty) {
      return '';
    }
    return '$year-${month.padLeft(2, '0')}';
  }

  String get employeeDisplayLabel {
    return <String?>[employeeName, employeeCode]
        .whereType<String>()
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .join(' • ');
  }

  factory PayslipModel.fromJson(Map<String, dynamic> json) {
    final generator = _asMap(json['generator']);
    final payrollLine = _asMap(json['payroll_line'] ?? json['payrollLine']);
    final employee = _asMap(payrollLine['employee']);
    final payrollRun = _asMap(
      payrollLine['payroll_run'] ?? payrollLine['payrollRun'],
    );
    final company = _asMap(json['company']);
    final employeeProfile = _mergeMaps(<Map<String, dynamic>>[
      _asMap(json['employee_profile']),
      _asMap(json['employeeProfile']),
      _asMap(payrollLine['employee_profile'] ?? payrollLine['employeeProfile']),
      employee,
    ]);
    return PayslipModel(
      id: JsonModel.nullableInt(json['id']),
      payslipNo: json['payslip_no']?.toString(),
      payrollLineId: JsonModel.nullableInt(
        json['payroll_line_id'] ?? payrollLine['id'],
      ),
      payslipDate: json['payslip_date']?.toString(),
      generatedBy: JsonModel.nullableInt(
        json['generated_by'] ?? generator['id'],
      ),
      generatorDisplayName: generator['display_name']?.toString(),
      generatorUsername: generator['username']?.toString(),
      employeeId: JsonModel.nullableInt(
        payrollLine['employee_id'] ??
            employeeProfile['id'] ??
            employee['id'] ??
            json['employee_id'],
      ),
      employeeName:
          employeeProfile['employee_name']?.toString() ??
          employee['employee_name']?.toString() ??
          json['employee_name']?.toString(),
      employeeCode:
          employeeProfile['employee_code']?.toString() ??
          employee['employee_code']?.toString() ??
          json['employee_code']?.toString(),
      payrollRunId: JsonModel.nullableInt(
        payrollLine['payroll_run_id'] ?? payrollRun['id'],
      ),
      payrollMonth:
          payrollRun['payroll_month']?.toString() ??
          json['payroll_month']?.toString(),
      payrollYear:
          payrollRun['payroll_year']?.toString() ??
          json['payroll_year']?.toString(),
      runDate:
          payrollRun['run_date']?.toString() ?? json['run_date']?.toString(),
      workingDays: JsonModel.nullableInt(json['working_days']),
      presentDays: JsonModel.nullableInt(json['present_days']),
      leaveDays: JsonModel.nullableInt(json['leave_days']),
      paidDays: JsonModel.nullableDouble(json['paid_days']),
      lopDays: JsonModel.nullableDouble(json['lop_days']),
      basicSalary: JsonModel.nullableDouble(json['basic_salary']),
      grossSalary: JsonModel.nullableDouble(json['gross_salary']),
      totalDeductions: JsonModel.nullableDouble(json['total_deductions']),
      ctcMonthly: JsonModel.nullableDouble(json['ctc_monthly']),
      netSalary:
          JsonModel.nullableDouble(json['net_salary']) ??
          JsonModel.nullableDouble(payrollLine['net_salary']),
      company: company.isEmpty ? null : PayslipCompanyModel.fromJson(company),
      employeeProfile: employeeProfile.isEmpty
          ? null
          : PayslipEmployeeProfileModel.fromJson(employeeProfile),
      earnings: _asList(
        json['earnings'],
      ).map(PayslipBreakupLineModel.fromJson).toList(growable: false),
      deductions: _asList(
        json['deductions'],
      ).map(PayslipBreakupLineModel.fromJson).toList(growable: false),
      remarks: json['remarks']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  @override
  String toString() => JsonModel.combineValues([
    payslipNo,
    payslipDate,
  ], defaultValue: 'Payslip');

  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (payslipNo != null) 'payslip_no': payslipNo,
    if (payrollLineId != null) 'payroll_line_id': payrollLineId,
    if (payslipDate != null) 'payslip_date': payslipDate,
    if (generatedBy != null) 'generated_by': generatedBy,
    if (generatorDisplayName != null || generatorUsername != null)
      'generator': <String, dynamic>{
        if (generatedBy != null) 'id': generatedBy,
        if (generatorDisplayName != null) 'display_name': generatorDisplayName,
        if (generatorUsername != null) 'username': generatorUsername,
      },
    if (employeeId != null ||
        employeeName != null ||
        employeeCode != null ||
        payrollRunId != null ||
        payrollMonth != null ||
        payrollYear != null ||
        runDate != null ||
        netSalary != null)
      'payroll_line': <String, dynamic>{
        if (payrollLineId != null) 'id': payrollLineId,
        if (employeeId != null) 'employee_id': employeeId,
        if (payrollRunId != null) 'payroll_run_id': payrollRunId,
        if (netSalary != null) 'net_salary': netSalary,
        if (employeeId != null || employeeName != null || employeeCode != null)
          'employee': <String, dynamic>{
            if (employeeId != null) 'id': employeeId,
            if (employeeName != null) 'employee_name': employeeName,
            if (employeeCode != null) 'employee_code': employeeCode,
          },
        if (payrollRunId != null ||
            payrollMonth != null ||
            payrollYear != null ||
            runDate != null)
          'payroll_run': <String, dynamic>{
            if (payrollRunId != null) 'id': payrollRunId,
            if (payrollMonth != null) 'payroll_month': payrollMonth,
            if (payrollYear != null) 'payroll_year': payrollYear,
            if (runDate != null) 'run_date': runDate,
          },
      },
    if (workingDays != null) 'working_days': workingDays,
    if (presentDays != null) 'present_days': presentDays,
    if (leaveDays != null) 'leave_days': leaveDays,
    if (paidDays != null) 'paid_days': paidDays,
    if (lopDays != null) 'lop_days': lopDays,
    if (basicSalary != null) 'basic_salary': basicSalary,
    if (grossSalary != null) 'gross_salary': grossSalary,
    if (totalDeductions != null) 'total_deductions': totalDeductions,
    if (ctcMonthly != null) 'ctc_monthly': ctcMonthly,
    if (netSalary != null) 'net_salary': netSalary,
    if (company != null) 'company': company!.toJson(),
    if (employeeProfile != null) 'employee_profile': employeeProfile!.toJson(),
    if (earnings.isNotEmpty)
      'earnings': earnings.map((item) => item.toJson()).toList(growable: false),
    if (deductions.isNotEmpty)
      'deductions': deductions
          .map((item) => item.toJson())
          .toList(growable: false),
    if (remarks != null) 'remarks': remarks,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}

class PayslipBreakupLineModel extends JsonModel {
  const PayslipBreakupLineModel({this.label, this.amount}) : super(id: null);

  final String? label;
  final double? amount;

  factory PayslipBreakupLineModel.fromJson(Map<String, dynamic> json) {
    return PayslipBreakupLineModel(
      label: json['label']?.toString(),
      amount: JsonModel.nullableDouble(json['amount']),
    );
  }

  @override
  String toString() => label ?? 'Amount Line';

  @override
  Map<String, dynamic> toJson() => {
    if (label != null) 'label': label,
    if (amount != null) 'amount': amount,
  };
}

class PayslipCompanyModel extends JsonModel {
  const PayslipCompanyModel({
    this.name,
    this.legalName,
    this.address,
    this.gstin,
    this.phone,
    this.email,
    this.logoPath,
  }) : super(id: null);

  final String? name;
  final String? legalName;
  final String? address;
  final String? gstin;
  final String? phone;
  final String? email;
  final String? logoPath;

  factory PayslipCompanyModel.fromJson(Map<String, dynamic> json) {
    return PayslipCompanyModel(
      name: json['name']?.toString(),
      legalName: json['legal_name']?.toString(),
      address: json['address']?.toString(),
      gstin: json['gstin']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      logoPath: json['logo_path']?.toString(),
    );
  }

  @override
  String toString() => name ?? legalName ?? 'Company';

  @override
  Map<String, dynamic> toJson() => {
    if (name != null) 'name': name,
    if (legalName != null) 'legal_name': legalName,
    if (address != null) 'address': address,
    if (gstin != null) 'gstin': gstin,
    if (phone != null) 'phone': phone,
    if (email != null) 'email': email,
    if (logoPath != null) 'logo_path': logoPath,
  };
}

class PayslipEmployeeProfileModel extends JsonModel {
  const PayslipEmployeeProfileModel({
    super.id,
    this.employeeCode,
    this.employeeName,
    this.departmentName,
    this.designationName,
    this.joiningDate,
    this.salaryMode,
    this.bankAccountNo,
    this.ifscCode,
    this.pfUanNo,
    this.esiNo,
    this.mobile,
    this.email,
  });

  final String? employeeCode;
  final String? employeeName;
  final String? departmentName;
  final String? designationName;
  final String? joiningDate;
  final String? salaryMode;
  final String? bankAccountNo;
  final String? ifscCode;
  final String? pfUanNo;
  final String? esiNo;
  final String? mobile;
  final String? email;

  factory PayslipEmployeeProfileModel.fromJson(Map<String, dynamic> json) {
    return PayslipEmployeeProfileModel(
      id: JsonModel.nullableInt(json['id']),
      employeeCode: json['employee_code']?.toString(),
      employeeName: json['employee_name']?.toString(),
      departmentName: json['department_name']?.toString(),
      designationName: json['designation_name']?.toString(),
      joiningDate: json['joining_date']?.toString(),
      salaryMode: json['salary_mode']?.toString(),
      bankAccountNo: json['bank_account_no']?.toString(),
      ifscCode: json['ifsc_code']?.toString(),
      pfUanNo: json['pf_uan_no']?.toString(),
      esiNo: json['esi_no']?.toString(),
      mobile: json['mobile']?.toString(),
      email: json['email']?.toString(),
    );
  }

  @override
  String toString() => employeeName ?? employeeCode ?? 'Employee';

  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (employeeCode != null) 'employee_code': employeeCode,
    if (employeeName != null) 'employee_name': employeeName,
    if (departmentName != null) 'department_name': departmentName,
    if (designationName != null) 'designation_name': designationName,
    if (joiningDate != null) 'joining_date': joiningDate,
    if (salaryMode != null) 'salary_mode': salaryMode,
    if (bankAccountNo != null) 'bank_account_no': bankAccountNo,
    if (ifscCode != null) 'ifsc_code': ifscCode,
    if (pfUanNo != null) 'pf_uan_no': pfUanNo,
    if (esiNo != null) 'esi_no': esiNo,
    if (mobile != null) 'mobile': mobile,
    if (email != null) 'email': email,
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

Map<String, dynamic> _mergeMaps(List<Map<String, dynamic>> maps) {
  final merged = <String, dynamic>{};
  for (final map in maps) {
    if (map.isEmpty) {
      continue;
    }
    merged.addAll(
      map.map(
        (key, value) => MapEntry(
          key,
          value is String && value.trim().isEmpty
              ? (merged[key] ?? value)
              : value,
        ),
      ),
    );
  }
  return merged;
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
