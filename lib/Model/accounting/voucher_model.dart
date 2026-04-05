import 'voucher_line_model.dart';

class VoucherModel {
  const VoucherModel({
    required this.id,
    required this.voucherNo,
    this.voucherDate,
    this.referenceNo,
    this.totalDebit = 0,
    this.totalCredit = 0,
    this.postingStatus,
    this.approvalStatus,
    this.adjustmentAmount,
    this.adjustmentAccountId,
    this.adjustmentRemarks,
    this.lines = const [],
    this.raw,
  });

  final int id;
  final String voucherNo;
  final String? voucherDate;
  final String? referenceNo;
  final double totalDebit;
  final double totalCredit;
  final String? postingStatus;
  final String? approvalStatus;
  final double? adjustmentAmount;
  final int? adjustmentAccountId;
  final String? adjustmentRemarks;
  final List<VoucherLineModel> lines;
  final Map<String, dynamic>? raw;

  factory VoucherModel.fromJson(Map<String, dynamic> json) {
    return VoucherModel(
      id: _parseInt(json['id']),
      voucherNo: json['voucher_no']?.toString() ?? '',
      voucherDate: json['voucher_date']?.toString(),
      referenceNo: json['reference_no']?.toString(),
      totalDebit: _parseDouble(json['total_debit']),
      totalCredit: _parseDouble(json['total_credit']),
      postingStatus: json['posting_status']?.toString(),
      approvalStatus: json['approval_status']?.toString(),
      adjustmentAmount: _nullableDouble(json['adjustment_amount']),
      adjustmentAccountId: _nullableInt(json['adjustment_account_id']),
      adjustmentRemarks: json['adjustment_remarks']?.toString(),
      lines: _mapLines(json['lines']),
      raw: json,
    );
  }

  static List<VoucherLineModel> _mapLines(dynamic value) {
    if (value is! List) {
      return <VoucherLineModel>[];
    }

    return value
        .whereType<Map<String, dynamic>>()
        .map(VoucherLineModel.fromJson)
        .toList(growable: false);
  }

  static int _parseInt(dynamic value) =>
      int.tryParse(value?.toString() ?? '') ?? 0;

  static int? _nullableInt(dynamic value) =>
      int.tryParse(value?.toString() ?? '');

  static double _parseDouble(dynamic value) =>
      double.tryParse(value?.toString() ?? '') ?? 0;

  static double? _nullableDouble(dynamic value) =>
      double.tryParse(value?.toString() ?? '');
}
