import '../common/json_model.dart';

class FinancialYearModel implements JsonModel {
  const FinancialYearModel({
    this.id,
    this.companyId,
    this.fyCode,
    this.fyName,
    this.yearCode = '',
    this.startDate,
    this.endDate,
    this.isCurrent = false,
    this.isLocked = false,
    this.lockDate,
    this.isActive = true,
    this.remarks,
    this.companyName,
    this.raw,
  });

  final int? id;
  final int? companyId;
  final String? fyCode;
  final String? fyName;
  final String yearCode;
  final String? startDate;
  final String? endDate;
  final bool isCurrent;
  final bool isLocked;
  final String? lockDate;
  final bool isActive;
  final String? remarks;
  final String? companyName;
  final Map<String, dynamic>? raw;

  @override
  String toString() => fyName?.trim().isNotEmpty == true
      ? fyName!
      : (fyCode?.trim().isNotEmpty == true ? fyCode! : yearCode);

  factory FinancialYearModel.fromJson(Map<String, dynamic> json) {
    final fyCode = json['fy_code']?.toString();
    final fyName = json['fy_name']?.toString();
    final company = _asMap(json['company']);
    return FinancialYearModel(
      id: _nullableInt(json['id']),
      companyId: _nullableInt(json['company_id'] ?? company['id']),
      fyCode: fyCode,
      fyName: fyName,
      yearCode:
          fyCode ??
          fyName ??
          json['year_code']?.toString() ??
          json['financial_year_code']?.toString() ??
          '',
      startDate: json['start_date']?.toString(),
      endDate: json['end_date']?.toString(),
      isCurrent: json['is_current'] == true || json['is_current'] == 1,
      isLocked: json['is_locked'] == true || json['is_locked'] == 1,
      lockDate: json['lock_date']?.toString(),
      isActive: json['is_active'] != false && json['is_active'] != 0,
      remarks: json['remarks']?.toString(),
      companyName:
          company['trade_name']?.toString() ??
          company['legal_name']?.toString() ??
          company['code']?.toString(),
      raw: json,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (companyId != null) 'company_id': companyId,
      if (fyCode != null) 'fy_code': fyCode,
      if (fyName != null) 'fy_name': fyName,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      'is_current': isCurrent,
      'is_locked': isLocked,
      if (lockDate != null) 'lock_date': lockDate,
      'is_active': isActive,
      if (remarks != null) 'remarks': remarks,
    };
  }

  static int? _nullableInt(dynamic value) =>
      int.tryParse(value?.toString() ?? '');

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    return const <String, dynamic>{};
  }
}
