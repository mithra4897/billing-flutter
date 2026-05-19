import '../../screen.dart';

class DocumentPostingLineModel extends JsonModel {
  const DocumentPostingLineModel({
    super.id,
    this.documentPostingId,
    this.lineNo,
    this.accountId,
    this.entrySide,
    this.amount,
    this.narration,
    this.sourceAmountField,
    this.sourceRuleId,
    this.createdAt,
    this.updatedAt,
  });
  final int? documentPostingId;
  final int? lineNo;
  final int? accountId;
  final String? entrySide;
  final double? amount;
  final String? narration;
  final String? sourceAmountField;
  final int? sourceRuleId;
  final String? createdAt;
  final String? updatedAt;

  factory DocumentPostingLineModel.fromJson(Map<String, dynamic> json) {
    return DocumentPostingLineModel(
      id: ModelValue.nullableInt(json['id']),
      documentPostingId: ModelValue.nullableInt(json['document_posting_id']),
      lineNo: ModelValue.nullableInt(json['line_no']),
      accountId: ModelValue.nullableInt(json['account_id']),
      entrySide: json['entry_side']?.toString(),
      amount: ModelValue.nullableDouble(json['amount']),
      narration: json['narration']?.toString(),
      sourceAmountField: json['source_amount_field']?.toString(),
      sourceRuleId: ModelValue.nullableInt(json['source_rule_id']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
  @override
  String toString() => 'Document Posting Line';


  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (documentPostingId != null) 'document_posting_id': documentPostingId,
    if (lineNo != null) 'line_no': lineNo,
    if (accountId != null) 'account_id': accountId,
    if (entrySide != null) 'entry_side': entrySide,
    if (amount != null) 'amount': amount,
    if (narration != null) 'narration': narration,
    if (sourceAmountField != null) 'source_amount_field': sourceAmountField,
    if (sourceRuleId != null) 'source_rule_id': sourceRuleId,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
