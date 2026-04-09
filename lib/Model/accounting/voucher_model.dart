import '../common/json_model.dart';
import 'voucher_line_model.dart';

class VoucherModel implements JsonModel {
  const VoucherModel({
    this.id,
    this.companyId,
    this.branchId,
    this.locationId,
    this.financialYearId,
    this.voucherTypeId,
    this.documentSeriesId,
    this.voucherNo,
    this.voucherDate,
    this.referenceNo,
    this.referenceDate,
    this.narration,
    this.totalDebit = 0,
    this.totalCredit = 0,
    this.adjustmentAmount,
    this.adjustmentAccountId,
    this.adjustmentRemarks,
    this.approvalStatus,
    this.postingStatus,
    this.isSystemGenerated = false,
    this.isActive = true,
    this.companyName,
    this.branchName,
    this.locationName,
    this.financialYearName,
    this.voucherTypeName,
    this.voucherCategory,
    this.documentSeriesName,
    this.lines = const <VoucherLineModel>[],
    this.raw,
  });

  final int? id;
  final int? companyId;
  final int? branchId;
  final int? locationId;
  final int? financialYearId;
  final int? voucherTypeId;
  final int? documentSeriesId;
  final String? voucherNo;
  final String? voucherDate;
  final String? referenceNo;
  final String? referenceDate;
  final String? narration;
  final double totalDebit;
  final double totalCredit;
  final double? adjustmentAmount;
  final int? adjustmentAccountId;
  final String? adjustmentRemarks;
  final String? approvalStatus;
  final String? postingStatus;
  final bool isSystemGenerated;
  final bool isActive;
  final String? companyName;
  final String? branchName;
  final String? locationName;
  final String? financialYearName;
  final String? voucherTypeName;
  final String? voucherCategory;
  final String? documentSeriesName;
  final List<VoucherLineModel> lines;
  final Map<String, dynamic>? raw;

  @override
  String toString() => voucherNo ?? 'New Voucher';

  factory VoucherModel.fromJson(Map<String, dynamic> json) {
    final company = _asMap(json['company']);
    final branch = _asMap(json['branch']);
    final location = _asMap(json['location']);
    final financialYear = _asMap(json['financialYear'] ?? json['financial_year']);
    final voucherType = _asMap(json['voucherType'] ?? json['voucher_type']);
    final documentSeries = _asMap(
      json['documentSeries'] ?? json['document_series'],
    );
    return VoucherModel(
      id: _nullableInt(json['id']),
      companyId: _nullableInt(json['company_id'] ?? company['id']),
      branchId: _nullableInt(json['branch_id'] ?? branch['id']),
      locationId: _nullableInt(json['location_id'] ?? location['id']),
      financialYearId: _nullableInt(
        json['financial_year_id'] ?? financialYear['id'],
      ),
      voucherTypeId: _nullableInt(json['voucher_type_id'] ?? voucherType['id']),
      documentSeriesId: _nullableInt(
        json['document_series_id'] ?? documentSeries['id'],
      ),
      voucherNo: json['voucher_no']?.toString(),
      voucherDate: json['voucher_date']?.toString(),
      referenceNo: json['reference_no']?.toString(),
      referenceDate: json['reference_date']?.toString(),
      narration: json['narration']?.toString(),
      totalDebit: _double(json['total_debit']) ?? 0,
      totalCredit: _double(json['total_credit']) ?? 0,
      adjustmentAmount: _double(json['adjustment_amount']),
      adjustmentAccountId: _nullableInt(json['adjustment_account_id']),
      adjustmentRemarks: json['adjustment_remarks']?.toString(),
      approvalStatus: json['approval_status']?.toString(),
      postingStatus: json['posting_status']?.toString(),
      isSystemGenerated: _bool(json['is_system_generated']),
      isActive: _bool(json['is_active'], fallback: true),
      companyName:
          company['trade_name']?.toString() ??
          company['legal_name']?.toString() ??
          company['code']?.toString(),
      branchName: branch['name']?.toString(),
      locationName: location['name']?.toString(),
      financialYearName:
          financialYear['fy_name']?.toString() ??
          financialYear['fy_code']?.toString(),
      voucherTypeName: voucherType['name']?.toString(),
      voucherCategory: voucherType['voucher_category']?.toString(),
      documentSeriesName:
          documentSeries['series_name']?.toString() ??
          documentSeries['prefix']?.toString(),
      lines: _mapLines(json['lines']),
      raw: json,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (companyId != null) 'company_id': companyId,
      if (branchId != null) 'branch_id': branchId,
      if (locationId != null) 'location_id': locationId,
      if (financialYearId != null) 'financial_year_id': financialYearId,
      if (voucherTypeId != null) 'voucher_type_id': voucherTypeId,
      'document_series_id': documentSeriesId,
      if (voucherNo != null) 'voucher_no': voucherNo,
      if (voucherDate != null) 'voucher_date': voucherDate,
      if (referenceNo != null) 'reference_no': referenceNo,
      if (referenceDate != null) 'reference_date': referenceDate,
      if (narration != null) 'narration': narration,
      'adjustment_account_id': adjustmentAccountId,
      if (adjustmentRemarks != null) 'adjustment_remarks': adjustmentRemarks,
      if (approvalStatus != null) 'approval_status': approvalStatus,
      if (postingStatus != null) 'posting_status': postingStatus,
      'is_system_generated': isSystemGenerated,
      'is_active': isActive,
      'lines': lines.map((item) => item.toJson()).toList(growable: false),
    };
  }

  static List<VoucherLineModel> _mapLines(dynamic value) {
    if (value is! List) {
      return const <VoucherLineModel>[];
    }

    return value
        .whereType<Map<String, dynamic>>()
        .map(VoucherLineModel.fromJson)
        .toList(growable: false);
  }

  static int? _nullableInt(dynamic value) =>
      int.tryParse(value?.toString() ?? '');

  static double? _double(dynamic value) =>
      double.tryParse(value?.toString() ?? '');

  static bool _bool(dynamic value, {bool fallback = false}) {
    if (value == null) return fallback;
    return value == true || value == 1 || value.toString() == '1';
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    return <String, dynamic>{};
  }
}
