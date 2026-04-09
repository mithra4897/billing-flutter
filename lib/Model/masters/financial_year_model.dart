class FinancialYearModel {
  const FinancialYearModel({
    required this.id,
    required this.companyId,
    this.fyCode,
    this.fyName,
    required this.yearCode,
    this.startDate,
    this.endDate,
    this.isCurrent = false,
    this.isLocked = false,
    this.isActive = true,
    this.raw,
  });

  final int id;
  final int companyId;
  final String? fyCode;
  final String? fyName;
  final String yearCode;
  final String? startDate;
  final String? endDate;
  final bool isCurrent;
  final bool isLocked;
  final bool isActive;
  final Map<String, dynamic>? raw;

  @override
  String toString() => fyName?.trim().isNotEmpty == true
      ? fyName!
      : (fyCode?.trim().isNotEmpty == true ? fyCode! : yearCode);

  factory FinancialYearModel.fromJson(Map<String, dynamic> json) {
    final fyCode = json['fy_code']?.toString();
    final fyName = json['fy_name']?.toString();
    return FinancialYearModel(
      id: _parseInt(json['id']),
      companyId: _parseInt(json['company_id']),
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
      isActive: json['is_active'] != false && json['is_active'] != 0,
      raw: json,
    );
  }

  static int _parseInt(dynamic value) =>
      int.tryParse(value?.toString() ?? '') ?? 0;
}
