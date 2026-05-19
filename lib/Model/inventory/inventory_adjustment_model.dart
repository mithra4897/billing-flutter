import '../../screen.dart';

class InventoryAdjustmentModel extends JsonModel {
  const InventoryAdjustmentModel({
    super.id,
    this.companyId,
    this.branchId,
    this.locationId,
    this.financialYearId,
    this.documentSeriesId,
    this.adjustmentNo,
    this.adjustmentDate,
    this.adjustmentType,
    this.reasonCode,
    this.voucherId,
    this.adjustmentStatus,
    this.remarks,
    this.isActive,
    this.createdBy,
    this.updatedBy,
    this.postedBy,
    this.postedAt,
    this.createdAt,
    this.updatedAt,
  });
  final int? companyId;
  final int? branchId;
  final int? locationId;
  final int? financialYearId;
  final int? documentSeriesId;
  final String? adjustmentNo;
  final String? adjustmentDate;
  final String? adjustmentType;
  final String? reasonCode;
  final int? voucherId;
  final String? adjustmentStatus;
  final String? remarks;
  final bool? isActive;
  final int? createdBy;
  final int? updatedBy;
  final int? postedBy;
  final String? postedAt;
  final String? createdAt;
  final String? updatedAt;

  factory InventoryAdjustmentModel.fromJson(Map<String, dynamic> json) {
    return InventoryAdjustmentModel(
      id: JsonModel.nullableInt(json['id']),
      companyId: JsonModel.nullableInt(json['company_id']),
      branchId: JsonModel.nullableInt(json['branch_id']),
      locationId: JsonModel.nullableInt(json['location_id']),
      financialYearId: JsonModel.nullableInt(json['financial_year_id']),
      documentSeriesId: JsonModel.nullableInt(json['document_series_id']),
      adjustmentNo: json['adjustment_no']?.toString(),
      adjustmentDate: json['adjustment_date']?.toString(),
      adjustmentType: json['adjustment_type']?.toString(),
      reasonCode: json['reason_code']?.toString(),
      voucherId: JsonModel.nullableInt(json['voucher_id']),
      adjustmentStatus: json['adjustment_status']?.toString(),
      remarks: json['remarks']?.toString(),
      isActive: json['is_active'] == null
          ? null
          : JsonModel.boolOf(json['is_active']),
      createdBy: JsonModel.nullableInt(json['created_by']),
      updatedBy: JsonModel.nullableInt(json['updated_by']),
      postedBy: JsonModel.nullableInt(json['posted_by']),
      postedAt: json['posted_at']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
  @override
  String toString() => JsonModel.combineValues([
    reasonCode,
    adjustmentNo,
    adjustmentDate,
  ], defaultValue: 'Inventory Adjustment');


  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (companyId != null) 'company_id': companyId,
    if (branchId != null) 'branch_id': branchId,
    if (locationId != null) 'location_id': locationId,
    if (financialYearId != null) 'financial_year_id': financialYearId,
    if (documentSeriesId != null) 'document_series_id': documentSeriesId,
    if (adjustmentNo != null) 'adjustment_no': adjustmentNo,
    if (adjustmentDate != null) 'adjustment_date': adjustmentDate,
    if (adjustmentType != null) 'adjustment_type': adjustmentType,
    if (reasonCode != null) 'reason_code': reasonCode,
    if (voucherId != null) 'voucher_id': voucherId,
    if (adjustmentStatus != null) 'adjustment_status': adjustmentStatus,
    if (remarks != null) 'remarks': remarks,
    if (isActive != null) 'is_active': isActive,
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (postedBy != null) 'posted_by': postedBy,
    if (postedAt != null) 'posted_at': postedAt,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
