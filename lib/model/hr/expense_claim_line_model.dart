import '../../screen.dart';

class ExpenseClaimLineModel extends JsonModel {
  const ExpenseClaimLineModel({
    super.id,
    this.expenseClaimId,
    this.lineNo,
    this.expenseDate,
    this.expenseCategory,
    this.description,
    this.amount,
    this.projectId,
    this.projectTaskId,
    this.remarks,
    this.createdAt,
    this.updatedAt,
  });
  final int? expenseClaimId;
  final int? lineNo;
  final String? expenseDate;
  final String? expenseCategory;
  final String? description;
  final double? amount;
  final int? projectId;
  final int? projectTaskId;
  final String? remarks;
  final String? createdAt;
  final String? updatedAt;

  factory ExpenseClaimLineModel.fromJson(Map<String, dynamic> json) {
    return ExpenseClaimLineModel(
      id: JsonModel.nullableInt(json['id']),
      expenseClaimId: JsonModel.nullableInt(json['expense_claim_id']),
      lineNo: JsonModel.nullableInt(json['line_no']),
      expenseDate: json['expense_date']?.toString(),
      expenseCategory: json['expense_category']?.toString(),
      description: json['description']?.toString(),
      amount: JsonModel.nullableDouble(json['amount']),
      projectId: JsonModel.nullableInt(json['project_id']),
      projectTaskId: JsonModel.nullableInt(json['project_task_id']),
      remarks: json['remarks']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
  @override
  String toString() => JsonModel.combineValues([
    lineNo,
    expenseDate,
  ], defaultValue: 'Expense Claim Line');


  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (expenseClaimId != null) 'expense_claim_id': expenseClaimId,
    if (lineNo != null) 'line_no': lineNo,
    if (expenseDate != null) 'expense_date': expenseDate,
    if (expenseCategory != null) 'expense_category': expenseCategory,
    if (description != null) 'description': description,
    if (amount != null) 'amount': amount,
    if (projectId != null) 'project_id': projectId,
    if (projectTaskId != null) 'project_task_id': projectTaskId,
    if (remarks != null) 'remarks': remarks,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
