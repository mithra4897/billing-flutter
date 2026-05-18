import '../../screen.dart';

class PurchaseReturnModel implements JsonModel {
  const PurchaseReturnModel({
    this.id,
    this.companyId,
    this.branchId,
    this.locationId,
    this.financialYearId,
    this.documentSeriesId,
    this.purchaseInvoiceId,
    this.returnNo,
    this.returnDate,
    this.supplierPartyId,
    this.subtotal,
    this.discountAmount,
    this.taxableAmount,
    this.cgstAmount,
    this.sgstAmount,
    this.igstAmount,
    this.cessAmount,
    this.roundOffAmount,
    this.totalAmount,
    this.voucherId,
    this.returnReason,
    this.returnStatus,
    this.notes,
    this.postedBy,
    this.postedAt,
    this.isActive,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final int? companyId;
  final int? branchId;
  final int? locationId;
  final int? financialYearId;
  final int? documentSeriesId;
  final int? purchaseInvoiceId;
  final String? returnNo;
  final String? returnDate;
  final int? supplierPartyId;
  final double? subtotal;
  final double? discountAmount;
  final double? taxableAmount;
  final double? cgstAmount;
  final double? sgstAmount;
  final double? igstAmount;
  final double? cessAmount;
  final double? roundOffAmount;
  final double? totalAmount;
  final int? voucherId;
  final String? returnReason;
  final String? returnStatus;
  final String? notes;
  final int? postedBy;
  final String? postedAt;
  final bool? isActive;
  final int? createdBy;
  final int? updatedBy;
  final String? createdAt;
  final String? updatedAt;

  factory PurchaseReturnModel.fromJson(Map<String, dynamic> json) {
    return PurchaseReturnModel(
      id: ModelValue.nullableInt(json['id']),
      companyId: ModelValue.nullableInt(json['company_id']),
      branchId: ModelValue.nullableInt(json['branch_id']),
      locationId: ModelValue.nullableInt(json['location_id']),
      financialYearId: ModelValue.nullableInt(json['financial_year_id']),
      documentSeriesId: ModelValue.nullableInt(json['document_series_id']),
      purchaseInvoiceId: ModelValue.nullableInt(json['purchase_invoice_id']),
      returnNo: json['return_no']?.toString(),
      returnDate: json['return_date']?.toString(),
      supplierPartyId: ModelValue.nullableInt(json['supplier_party_id']),
      subtotal: ModelValue.nullableDouble(json['subtotal']),
      discountAmount: ModelValue.nullableDouble(json['discount_amount']),
      taxableAmount: ModelValue.nullableDouble(json['taxable_amount']),
      cgstAmount: ModelValue.nullableDouble(json['cgst_amount']),
      sgstAmount: ModelValue.nullableDouble(json['sgst_amount']),
      igstAmount: ModelValue.nullableDouble(json['igst_amount']),
      cessAmount: ModelValue.nullableDouble(json['cess_amount']),
      roundOffAmount: ModelValue.nullableDouble(json['round_off_amount']),
      totalAmount: ModelValue.nullableDouble(json['total_amount']),
      voucherId: ModelValue.nullableInt(json['voucher_id']),
      returnReason: json['return_reason']?.toString(),
      returnStatus: json['return_status']?.toString(),
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
    if (purchaseInvoiceId != null) 'purchase_invoice_id': purchaseInvoiceId,
    if (returnNo != null) 'return_no': returnNo,
    if (returnDate != null) 'return_date': returnDate,
    if (supplierPartyId != null) 'supplier_party_id': supplierPartyId,
    if (subtotal != null) 'subtotal': subtotal,
    if (discountAmount != null) 'discount_amount': discountAmount,
    if (taxableAmount != null) 'taxable_amount': taxableAmount,
    if (cgstAmount != null) 'cgst_amount': cgstAmount,
    if (sgstAmount != null) 'sgst_amount': sgstAmount,
    if (igstAmount != null) 'igst_amount': igstAmount,
    if (cessAmount != null) 'cess_amount': cessAmount,
    if (roundOffAmount != null) 'round_off_amount': roundOffAmount,
    if (totalAmount != null) 'total_amount': totalAmount,
    if (voucherId != null) 'voucher_id': voucherId,
    if (returnReason != null) 'return_reason': returnReason,
    if (returnStatus != null) 'return_status': returnStatus,
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
