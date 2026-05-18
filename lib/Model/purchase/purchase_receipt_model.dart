import '../../screen.dart';

class PurchaseReceiptModel implements JsonModel {
  const PurchaseReceiptModel({
    this.id,
    this.companyId,
    this.branchId,
    this.locationId,
    this.financialYearId,
    this.documentSeriesId,
    this.purchaseOrderId,
    this.receiptNo,
    this.receiptDate,
    this.supplierPartyId,
    this.warehouseId,
    this.supplierDcNo,
    this.supplierDcDate,
    this.supplierInvoiceNo,
    this.supplierInvoiceDate,
    this.vehicleNo,
    this.transporterPartyId,
    this.lrNo,
    this.lrDate,
    this.voucherId,
    this.receiptStatus,
    this.notes,
    this.postedBy,
    this.postedAt,
    this.isActive,
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
  final int? documentSeriesId;
  final int? purchaseOrderId;
  final String? receiptNo;
  final String? receiptDate;
  final int? supplierPartyId;
  final int? warehouseId;
  final String? supplierDcNo;
  final String? supplierDcDate;
  final String? supplierInvoiceNo;
  final String? supplierInvoiceDate;
  final String? vehicleNo;
  final int? transporterPartyId;
  final String? lrNo;
  final String? lrDate;
  final int? voucherId;
  final String? receiptStatus;
  final String? notes;
  final int? postedBy;
  final String? postedAt;
  final bool? isActive;
  final int? createdBy;
  final int? updatedBy;
  final String? createdAt;
  final String? updatedAt;

  factory PurchaseReceiptModel.fromJson(Map<String, dynamic> json) {
    return PurchaseReceiptModel(
      id: ModelValue.nullableInt(json['id']),
      companyId: ModelValue.nullableInt(json['company_id']),
      branchId: ModelValue.nullableInt(json['branch_id']),
      locationId: ModelValue.nullableInt(json['location_id']),
      financialYearId: ModelValue.nullableInt(json['financial_year_id']),
      documentSeriesId: ModelValue.nullableInt(json['document_series_id']),
      purchaseOrderId: ModelValue.nullableInt(json['purchase_order_id']),
      receiptNo: json['receipt_no']?.toString(),
      receiptDate: json['receipt_date']?.toString(),
      supplierPartyId: ModelValue.nullableInt(json['supplier_party_id']),
      warehouseId: ModelValue.nullableInt(json['warehouse_id']),
      supplierDcNo: json['supplier_dc_no']?.toString(),
      supplierDcDate: json['supplier_dc_date']?.toString(),
      supplierInvoiceNo: json['supplier_invoice_no']?.toString(),
      supplierInvoiceDate: json['supplier_invoice_date']?.toString(),
      vehicleNo: json['vehicle_no']?.toString(),
      transporterPartyId: ModelValue.nullableInt(json['transporter_party_id']),
      lrNo: json['lr_no']?.toString(),
      lrDate: json['lr_date']?.toString(),
      voucherId: ModelValue.nullableInt(json['voucher_id']),
      receiptStatus: json['receipt_status']?.toString(),
      notes: json['notes']?.toString(),
      postedBy: ModelValue.nullableInt(json['posted_by']),
      postedAt: json['posted_at']?.toString(),
      isActive: json['is_active'] == null
          ? null
          : ModelValue.boolOf(json['is_active']),
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
    if (documentSeriesId != null) 'document_series_id': documentSeriesId,
    if (purchaseOrderId != null) 'purchase_order_id': purchaseOrderId,
    if (receiptNo != null) 'receipt_no': receiptNo,
    if (receiptDate != null) 'receipt_date': receiptDate,
    if (supplierPartyId != null) 'supplier_party_id': supplierPartyId,
    if (warehouseId != null) 'warehouse_id': warehouseId,
    if (supplierDcNo != null) 'supplier_dc_no': supplierDcNo,
    if (supplierDcDate != null) 'supplier_dc_date': supplierDcDate,
    if (supplierInvoiceNo != null) 'supplier_invoice_no': supplierInvoiceNo,
    if (supplierInvoiceDate != null)
      'supplier_invoice_date': supplierInvoiceDate,
    if (vehicleNo != null) 'vehicle_no': vehicleNo,
    if (transporterPartyId != null) 'transporter_party_id': transporterPartyId,
    if (lrNo != null) 'lr_no': lrNo,
    if (lrDate != null) 'lr_date': lrDate,
    if (voucherId != null) 'voucher_id': voucherId,
    if (receiptStatus != null) 'receipt_status': receiptStatus,
    if (notes != null) 'notes': notes,
    if (postedBy != null) 'posted_by': postedBy,
    if (postedAt != null) 'posted_at': postedAt,
    if (isActive != null) 'is_active': isActive,
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
