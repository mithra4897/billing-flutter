import '../../screen.dart';

class PurchaseReceiptModel extends JsonModel {
  const PurchaseReceiptModel({
    super.id,
    this.companyId,
    this.branchId,
    this.locationId,
    this.financialYearId,
    this.documentSeriesId,
    this.purchaseOrderId,
    this.receiptNo,
    this.receiptDate,
    this.supplierPartyId,
    this.supplierName,
    this.supplier,
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
    this.lines = const <PurchaseReceiptLineModel>[],
  });
  final int? companyId;
  final int? branchId;
  final int? locationId;
  final int? financialYearId;
  final int? documentSeriesId;
  final int? purchaseOrderId;
  final String? receiptNo;
  final String? receiptDate;
  final int? supplierPartyId;
  final String? supplierName;
  final Map<String, dynamic>? supplier;
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
  final List<PurchaseReceiptLineModel> lines;

  factory PurchaseReceiptModel.fromJson(Map<String, dynamic> json) {
    return PurchaseReceiptModel(
      id: JsonModel.nullableInt(json['id']),
      companyId: JsonModel.nullableInt(json['company_id']),
      branchId: JsonModel.nullableInt(json['branch_id']),
      locationId: JsonModel.nullableInt(json['location_id']),
      financialYearId: JsonModel.nullableInt(json['financial_year_id']),
      documentSeriesId: JsonModel.nullableInt(json['document_series_id']),
      purchaseOrderId: JsonModel.nullableInt(json['purchase_order_id']),
      receiptNo: json['receipt_no']?.toString(),
      receiptDate: json['receipt_date']?.toString(),
      supplierPartyId: JsonModel.nullableInt(json['supplier_party_id']),
      supplierName: json['supplier_name']?.toString(),
      supplier: JsonModel.mapOf(json['supplier']),
      warehouseId: JsonModel.nullableInt(json['warehouse_id']),
      supplierDcNo: json['supplier_dc_no']?.toString(),
      supplierDcDate: json['supplier_dc_date']?.toString(),
      supplierInvoiceNo: json['supplier_invoice_no']?.toString(),
      supplierInvoiceDate: json['supplier_invoice_date']?.toString(),
      vehicleNo: json['vehicle_no']?.toString(),
      transporterPartyId: JsonModel.nullableInt(json['transporter_party_id']),
      lrNo: json['lr_no']?.toString(),
      lrDate: json['lr_date']?.toString(),
      voucherId: JsonModel.nullableInt(json['voucher_id']),
      receiptStatus: json['receipt_status']?.toString(),
      notes: json['notes']?.toString(),
      postedBy: JsonModel.nullableInt(json['posted_by']),
      postedAt: json['posted_at']?.toString(),
      isActive: json['is_active'] == null
          ? null
          : JsonModel.boolOf(json['is_active']),
      createdBy: JsonModel.nullableInt(json['created_by']),
      updatedBy: JsonModel.nullableInt(json['updated_by']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      lines: JsonModel.listOf<PurchaseReceiptLineModel>(
        json['lines'],
        PurchaseReceiptLineModel.fromJson,
      ),
    );
  }
  @override
  String toString() => JsonModel.combineValues([
    receiptNo,
    vehicleNo,
    receiptDate,
  ], defaultValue: 'Purchase Receipt');

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
    if (supplierName != null) 'supplier_name': supplierName,
    if (supplier != null) 'supplier': supplier,
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
    'lines': lines.map((line) => line.toJson()).toList(growable: false),
  };
}
