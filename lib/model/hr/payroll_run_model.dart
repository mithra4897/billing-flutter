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
