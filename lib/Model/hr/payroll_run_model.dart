import '../../screen.dart';

class PayrollRunModel implements JsonModel {
  const PayrollRunModel({
    this.id,
    this.companyId,
    this.payrollMonth,
    this.payrollYear,
    this.runDate,
    this.status,
    this.voucherId,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    Map<String, dynamic>? raw,
  }) : _raw = raw;

  final int? id;
  final int? companyId;
  final String? payrollMonth;
  final String? payrollYear;
  final String? runDate;
  final String? status;
  final int? voucherId;
  final int? createdBy;
  final String? createdAt;
  final String? updatedAt;

  factory PayrollRunModel.fromJson(Map<String, dynamic> json) {
    return PayrollRunModel(
      id: ModelValue.nullableInt(json['id']),
      companyId: ModelValue.nullableInt(json['company_id']),
      payrollMonth: json['payroll_month']?.toString(),
      payrollYear: json['payroll_year']?.toString(),
      runDate: json['run_date']?.toString(),
      status: json['status']?.toString(),
      voucherId: ModelValue.nullableInt(json['voucher_id']),
      createdBy: ModelValue.nullableInt(json['created_by']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (companyId != null) 'company_id': companyId,
    if (payrollMonth != null) 'payroll_month': payrollMonth,
    if (payrollYear != null) 'payroll_year': payrollYear,
    if (runDate != null) 'run_date': runDate,
    if (status != null) 'status': status,
    if (voucherId != null) 'voucher_id': voucherId,
    if (createdBy != null) 'created_by': createdBy,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
