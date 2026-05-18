import '../../screen.dart';

class BudgetLineModel implements JsonModel {
  const BudgetLineModel({
    this.id,
    this.budgetId,
    this.lineNo,
    this.accountId,
    this.budgetAmount,
    this.remarks,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final int? budgetId;
  final int? lineNo;
  final int? accountId;
  final double? budgetAmount;
  final String? remarks;
  final String? createdAt;
  final String? updatedAt;

  factory BudgetLineModel.fromJson(Map<String, dynamic> json) {
    return BudgetLineModel(
      id: ModelValue.nullableInt(json['id']),
      budgetId: ModelValue.nullableInt(json['budget_id']),
      lineNo: ModelValue.nullableInt(json['line_no']),
      accountId: ModelValue.nullableInt(json['account_id']),
      budgetAmount: ModelValue.nullableDouble(json['budget_amount']),
      remarks: json['remarks']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (budgetId != null) 'budget_id': budgetId,
    if (lineNo != null) 'line_no': lineNo,
    if (accountId != null) 'account_id': accountId,
    if (budgetAmount != null) 'budget_amount': budgetAmount,
    if (remarks != null) 'remarks': remarks,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
