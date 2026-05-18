import '../../screen.dart';

class StockTransferModel implements JsonModel {
  const StockTransferModel({
    this.id,
    this.companyId,
    this.branchId,
    this.locationId,
    this.financialYearId,
    this.documentSeriesId,
    this.transferNo,
    this.transferDate,
    this.fromWarehouseId,
    this.toWarehouseId,
    this.transferStatus,
    this.remarks,
    this.receivedBy,
    this.receivedAt,
    this.voucherId,
    this.isActive,
    this.createdBy,
    this.updatedBy,
    this.postedBy,
    this.postedAt,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final int? companyId;
  final int? branchId;
  final int? locationId;
  final int? financialYearId;
  final int? documentSeriesId;
  final String? transferNo;
  final String? transferDate;
  final int? fromWarehouseId;
  final int? toWarehouseId;
  final String? transferStatus;
  final String? remarks;
  final int? receivedBy;
  final String? receivedAt;
  final int? voucherId;
  final bool? isActive;
  final int? createdBy;
  final int? updatedBy;
  final int? postedBy;
  final String? postedAt;
  final String? createdAt;
  final String? updatedAt;

  factory StockTransferModel.fromJson(Map<String, dynamic> json) {
    return StockTransferModel(
      id: ModelValue.nullableInt(json['id']),
      companyId: ModelValue.nullableInt(json['company_id']),
      branchId: ModelValue.nullableInt(json['branch_id']),
      locationId: ModelValue.nullableInt(json['location_id']),
      financialYearId: ModelValue.nullableInt(json['financial_year_id']),
      documentSeriesId: ModelValue.nullableInt(json['document_series_id']),
      transferNo: json['transfer_no']?.toString(),
      transferDate: json['transfer_date']?.toString(),
      fromWarehouseId: ModelValue.nullableInt(json['from_warehouse_id']),
      toWarehouseId: ModelValue.nullableInt(json['to_warehouse_id']),
      transferStatus: json['transfer_status']?.toString(),
      remarks: json['remarks']?.toString(),
      receivedBy: ModelValue.nullableInt(json['received_by']),
      receivedAt: json['received_at']?.toString(),
      voucherId: ModelValue.nullableInt(json['voucher_id']),
      isActive: json['is_active'] == null
          ? null
          : ModelValue.boolOf(json['is_active']),
      createdBy: ModelValue.nullableInt(json['created_by']),
      updatedBy: ModelValue.nullableInt(json['updated_by']),
      postedBy: ModelValue.nullableInt(json['posted_by']),
      postedAt: json['posted_at']?.toString(),
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
    if (transferNo != null) 'transfer_no': transferNo,
    if (transferDate != null) 'transfer_date': transferDate,
    if (fromWarehouseId != null) 'from_warehouse_id': fromWarehouseId,
    if (toWarehouseId != null) 'to_warehouse_id': toWarehouseId,
    if (transferStatus != null) 'transfer_status': transferStatus,
    if (remarks != null) 'remarks': remarks,
    if (receivedBy != null) 'received_by': receivedBy,
    if (receivedAt != null) 'received_at': receivedAt,
    if (voucherId != null) 'voucher_id': voucherId,
    if (isActive != null) 'is_active': isActive,
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (postedBy != null) 'posted_by': postedBy,
    if (postedAt != null) 'posted_at': postedAt,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
