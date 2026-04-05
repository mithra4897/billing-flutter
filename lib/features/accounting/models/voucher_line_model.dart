class VoucherLineModel {
  const VoucherLineModel({
    required this.id,
    required this.lineNo,
    required this.accountId,
    required this.entryType,
    required this.amount,
    this.partyId,
    this.billReferenceNo,
    this.lineNarration,
    this.project,
    this.costCenter,
    this.raw,
  });

  final int id;
  final int lineNo;
  final int accountId;
  final String entryType;
  final double amount;
  final int? partyId;
  final String? billReferenceNo;
  final String? lineNarration;
  final String? project;
  final String? costCenter;
  final Map<String, dynamic>? raw;

  factory VoucherLineModel.fromJson(Map<String, dynamic> json) {
    return VoucherLineModel(
      id: _parseInt(json['id']),
      lineNo: _parseInt(json['line_no']),
      accountId: _parseInt(json['account_id']),
      entryType: json['entry_type']?.toString() ?? '',
      amount: _parseDouble(json['amount']),
      partyId: _nullableInt(json['party_id']),
      billReferenceNo: json['bill_reference_no']?.toString(),
      lineNarration: json['line_narration']?.toString(),
      project: json['project']?.toString(),
      costCenter: json['cost_center']?.toString(),
      raw: json,
    );
  }

  static int _parseInt(dynamic value) =>
      int.tryParse(value?.toString() ?? '') ?? 0;

  static int? _nullableInt(dynamic value) =>
      int.tryParse(value?.toString() ?? '');

  static double _parseDouble(dynamic value) =>
      double.tryParse(value?.toString() ?? '') ?? 0;
}
