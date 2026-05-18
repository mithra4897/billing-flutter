import '../../screen.dart';

class DocumentPostingModel implements JsonModel {
  const DocumentPostingModel({
    this.id,
    this.companyId,
    this.branchId,
    this.locationId,
    this.financialYearId,
    this.documentModule,
    this.documentTable,
    this.documentId,
    this.documentNo,
    this.documentDate,
    this.postingRuleGroupId,
    this.voucherId,
    this.postingStatus,
    this.postedAt,
    this.reversedAt,
    this.errorMessage,
    this.remarks,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
    Map<String, dynamic>? raw,
  }) : _raw = raw;

  final int? id;
  final int? companyId;
  final int? branchId;
  final int? locationId;
  final int? financialYearId;
  final String? documentModule;
  final String? documentTable;
  final int? documentId;
  final String? documentNo;
  final String? documentDate;
  final int? postingRuleGroupId;
  final int? voucherId;
  final String? postingStatus;
  final String? postedAt;
  final String? reversedAt;
  final String? errorMessage;
  final String? remarks;
  final int? createdBy;
  final int? updatedBy;
  final String? createdAt;
  final String? updatedAt;

  factory DocumentPostingModel.fromJson(Map<String, dynamic> json) {
    return DocumentPostingModel(
      id: ModelValue.nullableInt(json['id']),
      companyId: ModelValue.nullableInt(json['company_id']),
      branchId: ModelValue.nullableInt(json['branch_id']),
      locationId: ModelValue.nullableInt(json['location_id']),
      financialYearId: ModelValue.nullableInt(json['financial_year_id']),
      documentModule: json['document_module']?.toString(),
      documentTable: json['document_table']?.toString(),
      documentId: ModelValue.nullableInt(json['document_id']),
      documentNo: json['document_no']?.toString(),
      documentDate: json['document_date']?.toString(),
      postingRuleGroupId: ModelValue.nullableInt(json['posting_rule_group_id']),
      voucherId: ModelValue.nullableInt(json['voucher_id']),
      postingStatus: json['posting_status']?.toString(),
      postedAt: json['posted_at']?.toString(),
      reversedAt: json['reversed_at']?.toString(),
      errorMessage: json['error_message']?.toString(),
      remarks: json['remarks']?.toString(),
      createdBy: ModelValue.nullableInt(json['created_by']),
      updatedBy: ModelValue.nullableInt(json['updated_by']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (companyId != null) 'company_id': companyId,
    if (branchId != null) 'branch_id': branchId,
    if (locationId != null) 'location_id': locationId,
    if (financialYearId != null) 'financial_year_id': financialYearId,
    if (documentModule != null) 'document_module': documentModule,
    if (documentTable != null) 'document_table': documentTable,
    if (documentId != null) 'document_id': documentId,
    if (documentNo != null) 'document_no': documentNo,
    if (documentDate != null) 'document_date': documentDate,
    if (postingRuleGroupId != null) 'posting_rule_group_id': postingRuleGroupId,
    if (voucherId != null) 'voucher_id': voucherId,
    if (postingStatus != null) 'posting_status': postingStatus,
    if (postedAt != null) 'posted_at': postedAt,
    if (reversedAt != null) 'reversed_at': reversedAt,
    if (errorMessage != null) 'error_message': errorMessage,
    if (remarks != null) 'remarks': remarks,
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
