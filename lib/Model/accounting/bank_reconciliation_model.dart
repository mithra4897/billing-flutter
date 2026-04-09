import '../common/json_model.dart';

class BankReconciliationModel implements JsonModel {
  const BankReconciliationModel({
    this.id,
    this.accountId,
    this.voucherLineId,
    this.bankDate,
    this.clearedDate,
    this.reconciliationStatus,
    this.bankReferenceNo,
    this.remarks,
    this.reconciledBy,
    this.reconciledAt,
    this.accountCode,
    this.accountName,
    this.voucherAccountName,
    this.voucherAccountCode,
    this.voucherNo,
    this.voucherDate,
    this.voucherAmount,
    this.entryType,
    this.raw,
  });

  final int? id;
  final int? accountId;
  final int? voucherLineId;
  final String? bankDate;
  final String? clearedDate;
  final String? reconciliationStatus;
  final String? bankReferenceNo;
  final String? remarks;
  final String? reconciledBy;
  final String? reconciledAt;
  final String? accountCode;
  final String? accountName;
  final String? voucherAccountName;
  final String? voucherAccountCode;
  final String? voucherNo;
  final String? voucherDate;
  final double? voucherAmount;
  final String? entryType;
  final Map<String, dynamic>? raw;

  @override
  String toString() => bankReferenceNo ?? voucherNo ?? 'Bank Reconciliation';

  factory BankReconciliationModel.fromJson(Map<String, dynamic> json) {
    final account = _asMap(json['account']);
    final voucherLine = _asMap(json['voucher_line'] ?? json['voucherLine']);
    final voucherAccount = _asMap(voucherLine['account']);
    final voucher = _asMap(voucherLine['voucher']);
    final reconciler = _asMap(json['reconciler']);
    return BankReconciliationModel(
      id: _nullableInt(json['id']),
      accountId: _nullableInt(json['account_id'] ?? account['id']),
      voucherLineId: _nullableInt(json['voucher_line_id'] ?? voucherLine['id']),
      bankDate: json['bank_date']?.toString(),
      clearedDate: json['cleared_date']?.toString(),
      reconciliationStatus: json['reconciliation_status']?.toString(),
      bankReferenceNo: json['bank_reference_no']?.toString(),
      remarks: json['remarks']?.toString(),
      reconciledBy:
          reconciler['display_name']?.toString() ??
          reconciler['username']?.toString(),
      reconciledAt: json['reconciled_at']?.toString(),
      accountCode: account['account_code']?.toString(),
      accountName: account['account_name']?.toString(),
      voucherAccountCode: voucherAccount['account_code']?.toString(),
      voucherAccountName: voucherAccount['account_name']?.toString(),
      voucherNo: voucher['voucher_no']?.toString(),
      voucherDate: voucher['voucher_date']?.toString(),
      voucherAmount: _double(voucherLine['amount']),
      entryType: voucherLine['entry_type']?.toString(),
      raw: json,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (accountId != null) 'account_id': accountId,
      if (voucherLineId != null) 'voucher_line_id': voucherLineId,
      if (bankDate != null) 'bank_date': bankDate,
      if (clearedDate != null) 'cleared_date': clearedDate,
      if (reconciliationStatus != null)
        'reconciliation_status': reconciliationStatus,
      if (bankReferenceNo != null) 'bank_reference_no': bankReferenceNo,
      if (remarks != null) 'remarks': remarks,
    };
  }

  static int? _nullableInt(dynamic value) =>
      int.tryParse(value?.toString() ?? '');

  static double? _double(dynamic value) =>
      double.tryParse(value?.toString() ?? '');

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    return <String, dynamic>{};
  }
}
