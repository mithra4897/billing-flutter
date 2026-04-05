import '../common/json_model.dart';
import '../common/model_value.dart';

class ProjectExpenseModel implements JsonModel {
  const ProjectExpenseModel({
    this.id,
    this.projectId,
    this.projectTaskId,
    this.expenseDate,
    this.expenseCategory,
    this.description,
    this.supplierPartyId,
    this.purchaseInvoiceId,
    this.amount,
    this.voucherId,
    this.expenseStatus,
    this.remarks,
    this.raw,
  });

  final int? id;
  final int? projectId;
  final int? projectTaskId;
  final String? expenseDate;
  final String? expenseCategory;
  final String? description;
  final int? supplierPartyId;
  final int? purchaseInvoiceId;
  final double? amount;
  final int? voucherId;
  final String? expenseStatus;
  final String? remarks;
  final Map<String, dynamic>? raw;

  factory ProjectExpenseModel.fromJson(Map<String, dynamic> json) {
    return ProjectExpenseModel(
      id: ModelValue.nullableInt(json['id']),
      projectId: ModelValue.nullableInt(json['project_id']),
      projectTaskId: ModelValue.nullableInt(json['project_task_id']),
      expenseDate: json['expense_date']?.toString(),
      expenseCategory: json['expense_category']?.toString(),
      description: json['description']?.toString(),
      supplierPartyId: ModelValue.nullableInt(json['supplier_party_id']),
      purchaseInvoiceId: ModelValue.nullableInt(json['purchase_invoice_id']),
      amount: ModelValue.nullableDouble(json['amount']),
      voucherId: ModelValue.nullableInt(json['voucher_id']),
      expenseStatus: json['expense_status']?.toString(),
      remarks: json['remarks']?.toString(),
      raw: json,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    if (projectId != null) 'project_id': projectId,
    if (projectTaskId != null) 'project_task_id': projectTaskId,
    if (expenseDate != null) 'expense_date': expenseDate,
    if (expenseCategory != null) 'expense_category': expenseCategory,
    if (description != null) 'description': description,
    if (supplierPartyId != null) 'supplier_party_id': supplierPartyId,
    if (purchaseInvoiceId != null) 'purchase_invoice_id': purchaseInvoiceId,
    if (amount != null) 'amount': amount,
    if (voucherId != null) 'voucher_id': voucherId,
    if (expenseStatus != null) 'expense_status': expenseStatus,
    if (remarks != null) 'remarks': remarks,
  };
}
