class FinancialYearModel {
  const FinancialYearModel({
    required this.id,
    required this.companyId,
    required this.yearCode,
    this.startDate,
    this.endDate,
    this.isActive = true,
    this.raw,
  });

  final int id;
  final int companyId;
  final String yearCode;
  final String? startDate;
  final String? endDate;
  final bool isActive;
  final Map<String, dynamic>? raw;

  factory FinancialYearModel.fromJson(Map<String, dynamic> json) {
    return FinancialYearModel(
      id: _parseInt(json['id']),
      companyId: _parseInt(json['company_id']),
      yearCode:
          json['year_code']?.toString() ??
          json['financial_year_code']?.toString() ??
          '',
      startDate: json['start_date']?.toString(),
      endDate: json['end_date']?.toString(),
      isActive: json['is_active'] != false && json['is_active'] != 0,
      raw: json,
    );
  }

  static int _parseInt(dynamic value) =>
      int.tryParse(value?.toString() ?? '') ?? 0;
}
