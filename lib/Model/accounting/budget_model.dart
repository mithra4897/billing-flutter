import '../../screen.dart';

class BudgetModel extends JsonModel {
  const BudgetModel({
    super.id,
    this.companyId,
    this.financialYearId,
    this.budgetCode,
    this.budgetName,
    this.dateFrom,
    this.dateTo,
    this.budgetStatus,
    this.notes,
    this.isActive,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  });
  final int? companyId;
  final int? financialYearId;
  final String? budgetCode;
  final String? budgetName;
  final String? dateFrom;
  final String? dateTo;
  final String? budgetStatus;
  final String? notes;
  final bool? isActive;
  final int? createdBy;
  final int? updatedBy;
  final String? createdAt;
  final String? updatedAt;

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      id: JsonModel.nullableInt(json['id']),
      companyId: JsonModel.nullableInt(json['company_id']),
      financialYearId: JsonModel.nullableInt(json['financial_year_id']),
      budgetCode: json['budget_code']?.toString(),
      budgetName: json['budget_name']?.toString(),
      dateFrom: json['date_from']?.toString(),
      dateTo: json['date_to']?.toString(),
      budgetStatus: json['budget_status']?.toString(),
      notes: json['notes']?.toString(),
      isActive: json['is_active'] == null
          ? null
          : JsonModel.boolOf(json['is_active']),
      createdBy: JsonModel.nullableInt(json['created_by']),
      updatedBy: JsonModel.nullableInt(json['updated_by']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
  @override
  String toString() => JsonModel.combineValues([
    budgetName,
    budgetCode,
    budgetStatus,
  ], defaultValue: 'Budget');


  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (companyId != null) 'company_id': companyId,
    if (financialYearId != null) 'financial_year_id': financialYearId,
    if (budgetCode != null) 'budget_code': budgetCode,
    if (budgetName != null) 'budget_name': budgetName,
    if (dateFrom != null) 'date_from': dateFrom,
    if (dateTo != null) 'date_to': dateTo,
    if (budgetStatus != null) 'budget_status': budgetStatus,
    if (notes != null) 'notes': notes,
    if (isActive != null) 'is_active': isActive,
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
