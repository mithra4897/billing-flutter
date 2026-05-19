import '../../screen.dart';

class ProductionReceiptModel extends JsonModel {
  const ProductionReceiptModel({
    super.id,
    this.companyId,
    this.branchId,
    this.locationId,
    this.financialYearId,
    this.documentSeriesId,
    this.receiptNo,
    this.receiptDate,
    this.productionOrderId,
    this.warehouseId,
    this.receiptStatus,
    this.receiptType,
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
  final String? receiptNo;
  final String? receiptDate;
  final int? productionOrderId;
  final int? warehouseId;
  final String? receiptStatus;
  final String? receiptType;
  final String? remarks;
  final int? voucherId;
  final int? postedBy;
  final String? postedAt;
  final int? createdBy;
  final int? updatedBy;
  final bool? isActive;
  final String? createdAt;
  final String? updatedAt;

  factory ProductionReceiptModel.fromJson(Map<String, dynamic> json) {
    return ProductionReceiptModel(
      id: ModelValue.nullableInt(json['id']),
      companyId: ModelValue.nullableInt(json['company_id']),
      branchId: ModelValue.nullableInt(json['branch_id']),
      locationId: ModelValue.nullableInt(json['location_id']),
      financialYearId: ModelValue.nullableInt(json['financial_year_id']),
      documentSeriesId: ModelValue.nullableInt(json['document_series_id']),
      receiptNo: json['receipt_no']?.toString(),
      receiptDate: json['receipt_date']?.toString(),
      productionOrderId: ModelValue.nullableInt(json['production_order_id']),
      warehouseId: ModelValue.nullableInt(json['warehouse_id']),
      receiptStatus: json['receipt_status']?.toString(),
      receiptType: json['receipt_type']?.toString(),
      remarks: json['remarks']?.toString(),
      voucherId: ModelValue.nullableInt(json['voucher_id']),
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
  String toString() => 'Production Receipt';


  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (companyId != null) 'company_id': companyId,
    if (branchId != null) 'branch_id': branchId,
    if (locationId != null) 'location_id': locationId,
    if (financialYearId != null) 'financial_year_id': financialYearId,
    if (documentSeriesId != null) 'document_series_id': documentSeriesId,
    if (receiptNo != null) 'receipt_no': receiptNo,
    if (receiptDate != null) 'receipt_date': receiptDate,
    if (productionOrderId != null) 'production_order_id': productionOrderId,
    if (warehouseId != null) 'warehouse_id': warehouseId,
    if (receiptStatus != null) 'receipt_status': receiptStatus,
    if (receiptType != null) 'receipt_type': receiptType,
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
