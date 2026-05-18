import '../../screen.dart';

class StockDamageEntryModel implements JsonModel {
  const StockDamageEntryModel({
    this.id,
    this.companyId,
    this.branchId,
    this.locationId,
    this.financialYearId,
    this.documentSeriesId,
    this.damageNo,
    this.damageDate,
    this.warehouseId,
    this.damageType,
    this.voucherId,
    this.damageStatus,
    this.remarks,
    this.postedBy,
    this.postedAt,
    this.createdBy,
    this.updatedBy,
    this.isActive,
    this.createdAt,
    this.updatedAt,
    Map<String, dynamic>? raw,
  }) : _raw = raw;

  final int? id;
  final int? companyId;
  final int? branchId;
  final int? locationId;
  final int? financialYearId;
  final int? documentSeriesId;
  final String? damageNo;
  final String? damageDate;
  final int? warehouseId;
  final String? damageType;
  final int? voucherId;
  final String? damageStatus;
  final String? remarks;
  final int? postedBy;
  final String? postedAt;
  final int? createdBy;
  final int? updatedBy;
  final bool? isActive;
  final String? createdAt;
  final String? updatedAt;

  factory StockDamageEntryModel.fromJson(Map<String, dynamic> json) {
    return StockDamageEntryModel(
      id: ModelValue.nullableInt(json['id']),
      companyId: ModelValue.nullableInt(json['company_id']),
      branchId: ModelValue.nullableInt(json['branch_id']),
      locationId: ModelValue.nullableInt(json['location_id']),
      financialYearId: ModelValue.nullableInt(json['financial_year_id']),
      documentSeriesId: ModelValue.nullableInt(json['document_series_id']),
      damageNo: json['damage_no']?.toString(),
      damageDate: json['damage_date']?.toString(),
      warehouseId: ModelValue.nullableInt(json['warehouse_id']),
      damageType: json['damage_type']?.toString(),
      voucherId: ModelValue.nullableInt(json['voucher_id']),
      damageStatus: json['damage_status']?.toString(),
      remarks: json['remarks']?.toString(),
      postedBy: ModelValue.nullableInt(json['posted_by']),
      postedAt: json['posted_at']?.toString(),
      createdBy: ModelValue.nullableInt(json['created_by']),
      updatedBy: ModelValue.nullableInt(json['updated_by']),
      isActive: json['is_active'] == null
          ? null
          : ModelValue.boolOf(json['is_active']),
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
    if (documentSeriesId != null) 'document_series_id': documentSeriesId,
    if (damageNo != null) 'damage_no': damageNo,
    if (damageDate != null) 'damage_date': damageDate,
    if (warehouseId != null) 'warehouse_id': warehouseId,
    if (damageType != null) 'damage_type': damageType,
    if (voucherId != null) 'voucher_id': voucherId,
    if (damageStatus != null) 'damage_status': damageStatus,
    if (remarks != null) 'remarks': remarks,
    if (postedBy != null) 'posted_by': postedBy,
    if (postedAt != null) 'posted_at': postedAt,
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (isActive != null) 'is_active': isActive,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
