import '../common/json_model.dart';

class VoucherLineModel implements JsonModel {
  const VoucherLineModel({
    this.id,
    this.lineNo,
    this.accountId,
    this.accountCode,
    this.accountName,
    this.partyId,
    this.partyName,
    this.entryType,
    this.amount,
    this.billReferenceNo,
    this.billReferenceDate,
    this.billReferenceType,
    this.chequeNo,
    this.chequeDate,
    this.bankReferenceNo,
    this.bankReferenceDate,
    this.costCenter,
    this.department,
    this.project,
    this.lineNarration,
    this.raw,
  });

  final int? id;
  final int? lineNo;
  final int? accountId;
  final String? accountCode;
  final String? accountName;
  final int? partyId;
  final String? partyName;
  final String? entryType;
  final double? amount;
  final String? billReferenceNo;
  final String? billReferenceDate;
  final String? billReferenceType;
  final String? chequeNo;
  final String? chequeDate;
  final String? bankReferenceNo;
  final String? bankReferenceDate;
  final String? costCenter;
  final String? department;
  final String? project;
  final String? lineNarration;
  final Map<String, dynamic>? raw;

  @override
  String toString() => accountName ?? accountCode ?? 'Voucher Line';

  factory VoucherLineModel.fromJson(Map<String, dynamic> json) {
    final account = _asMap(json['account']);
    final party = _asMap(json['party']);
    return VoucherLineModel(
      id: _nullableInt(json['id']),
      lineNo: _nullableInt(json['line_no']),
      accountId: _nullableInt(json['account_id'] ?? account['id']),
      accountCode: account['account_code']?.toString(),
      accountName: account['account_name']?.toString(),
      partyId: _nullableInt(json['party_id'] ?? party['id']),
      partyName:
          party['display_name']?.toString() ??
          party['party_name']?.toString(),
      entryType: json['entry_type']?.toString(),
      amount: _double(json['amount']),
      billReferenceNo: json['bill_reference_no']?.toString(),
      billReferenceDate: json['bill_reference_date']?.toString(),
      billReferenceType: json['bill_reference_type']?.toString(),
      chequeNo: json['cheque_no']?.toString(),
      chequeDate: json['cheque_date']?.toString(),
      bankReferenceNo: json['bank_reference_no']?.toString(),
      bankReferenceDate: json['bank_reference_date']?.toString(),
      costCenter: json['cost_center']?.toString(),
      department: json['department']?.toString(),
      project: json['project']?.toString(),
      lineNarration: json['line_narration']?.toString(),
      raw: json,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (lineNo != null) 'line_no': lineNo,
      if (accountId != null) 'account_id': accountId,
      'party_id': partyId,
      if (entryType != null) 'entry_type': entryType,
      if (amount != null) 'amount': amount,
      if (billReferenceNo != null) 'bill_reference_no': billReferenceNo,
      if (billReferenceDate != null) 'bill_reference_date': billReferenceDate,
      if (billReferenceType != null) 'bill_reference_type': billReferenceType,
      if (chequeNo != null) 'cheque_no': chequeNo,
      if (chequeDate != null) 'cheque_date': chequeDate,
      if (bankReferenceNo != null) 'bank_reference_no': bankReferenceNo,
      if (bankReferenceDate != null) 'bank_reference_date': bankReferenceDate,
      if (costCenter != null) 'cost_center': costCenter,
      if (department != null) 'department': department,
      if (project != null) 'project': project,
      if (lineNarration != null) 'line_narration': lineNarration,
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
