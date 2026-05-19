import '../../screen.dart';

class ProductionMaterialIssueModel extends JsonModel {
  const ProductionMaterialIssueModel({
    super.id,
    this.companyId,
    this.branchId,
    this.locationId,
    this.financialYearId,
    this.documentSeriesId,
    this.issueNo,
    this.issueDate,
    this.productionOrderId,
    this.warehouseId,
    this.issueStatus,
    this.issueMode,
    this.remarks,
    this.voucherId,
    this.postedBy,
    this.postedAt,
    this.createdBy,
    this.updatedBy,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });
  final int? companyId;
  final int? branchId;
  final int? locationId;
  final int? financialYearId;
  final int? documentSeriesId;
  final String? issueNo;
  final String? issueDate;
  final int? productionOrderId;
  final int? warehouseId;
  final String? issueStatus;
  final String? issueMode;
  final String? remarks;
  final int? voucherId;
  final int? postedBy;
  final String? postedAt;
  final int? createdBy;
  final int? updatedBy;
  final bool? isActive;
  final String? createdAt;
  final String? updatedAt;

  factory ProductionMaterialIssueModel.fromJson(Map<String, dynamic> json) {
    return ProductionMaterialIssueModel(
      id: JsonModel.nullableInt(json['id']),
      companyId: JsonModel.nullableInt(json['company_id']),
      branchId: JsonModel.nullableInt(json['branch_id']),
      locationId: JsonModel.nullableInt(json['location_id']),
      financialYearId: JsonModel.nullableInt(json['financial_year_id']),
      documentSeriesId: JsonModel.nullableInt(json['document_series_id']),
      issueNo: json['issue_no']?.toString(),
      issueDate: json['issue_date']?.toString(),
      productionOrderId: JsonModel.nullableInt(json['production_order_id']),
      warehouseId: JsonModel.nullableInt(json['warehouse_id']),
      issueStatus: json['issue_status']?.toString(),
      issueMode: json['issue_mode']?.toString(),
      remarks: json['remarks']?.toString(),
      voucherId: JsonModel.nullableInt(json['voucher_id']),
      postedBy: JsonModel.nullableInt(json['posted_by']),
      postedAt: json['posted_at']?.toString(),
      createdBy: JsonModel.nullableInt(json['created_by']),
      updatedBy: JsonModel.nullableInt(json['updated_by']),
      isActive: json['is_active'] == null
          ? null
          : JsonModel.boolOf(json['is_active']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
  @override
  String toString() => JsonModel.combineValues([
    issueNo,
    issueDate,
    issueStatus,
  ], defaultValue: 'Production Material Issue');


  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (companyId != null) 'company_id': companyId,
    if (branchId != null) 'branch_id': branchId,
    if (locationId != null) 'location_id': locationId,
    if (financialYearId != null) 'financial_year_id': financialYearId,
    if (documentSeriesId != null) 'document_series_id': documentSeriesId,
    if (issueNo != null) 'issue_no': issueNo,
    if (issueDate != null) 'issue_date': issueDate,
    if (productionOrderId != null) 'production_order_id': productionOrderId,
    if (warehouseId != null) 'warehouse_id': warehouseId,
    if (issueStatus != null) 'issue_status': issueStatus,
    if (issueMode != null) 'issue_mode': issueMode,
    if (remarks != null) 'remarks': remarks,
    if (voucherId != null) 'voucher_id': voucherId,
    if (postedBy != null) 'posted_by': postedBy,
    if (postedAt != null) 'posted_at': postedAt,
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (isActive != null) 'is_active': isActive,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
