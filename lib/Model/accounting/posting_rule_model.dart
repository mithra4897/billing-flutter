import '../../screen.dart';

class PostingRuleModel extends JsonModel {
  const PostingRuleModel({
    super.id,
    this.postingRuleGroupId,
    this.lineNo,
    this.entrySide,
    this.accountSourceType,
    this.fixedAccountId,
    this.amountSource,
    this.narrationTemplate,
    this.priorityOrder,
    this.isActive,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  });
  final int? postingRuleGroupId;
  final int? lineNo;
  final String? entrySide;
  final String? accountSourceType;
  final int? fixedAccountId;
  final String? amountSource;
  final String? narrationTemplate;
  final int? priorityOrder;
  final bool? isActive;
  final int? createdBy;
  final int? updatedBy;
  final String? createdAt;
  final String? updatedAt;

  factory PostingRuleModel.fromJson(Map<String, dynamic> json) {
    return PostingRuleModel(
      id: ModelValue.nullableInt(json['id']),
      postingRuleGroupId: ModelValue.nullableInt(json['posting_rule_group_id']),
      lineNo: ModelValue.nullableInt(json['line_no']),
      entrySide: json['entry_side']?.toString(),
      accountSourceType: json['account_source_type']?.toString(),
      fixedAccountId: ModelValue.nullableInt(json['fixed_account_id']),
      amountSource: json['amount_source']?.toString(),
      narrationTemplate: json['narration_template']?.toString(),
      priorityOrder: ModelValue.nullableInt(json['priority_order']),
      isActive: json['is_active'] == null
          ? null
          : ModelValue.boolOf(json['is_active']),
      createdBy: ModelValue.nullableInt(json['created_by']),
      updatedBy: ModelValue.nullableInt(json['updated_by']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
  @override
  String toString() => 'Posting Rule';


  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (postingRuleGroupId != null) 'posting_rule_group_id': postingRuleGroupId,
    if (lineNo != null) 'line_no': lineNo,
    if (entrySide != null) 'entry_side': entrySide,
    if (accountSourceType != null) 'account_source_type': accountSourceType,
    if (fixedAccountId != null) 'fixed_account_id': fixedAccountId,
    if (amountSource != null) 'amount_source': amountSource,
    if (narrationTemplate != null) 'narration_template': narrationTemplate,
    if (priorityOrder != null) 'priority_order': priorityOrder,
    if (isActive != null) 'is_active': isActive,
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
