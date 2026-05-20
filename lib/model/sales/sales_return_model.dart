import '../../screen.dart';

class SalesReturnModel extends JsonModel {
  const SalesReturnModel({
    super.id,
    this.companyId,
    this.branchId,
    this.locationId,
    this.financialYearId,
    this.documentSeriesId,
    this.salesInvoiceId,
    this.returnNo,
    this.returnDate,
    this.customerPartyId,
    this.subtotal,
    this.discountAmount,
    this.taxableAmount,
    this.cgstAmount,
    this.sgstAmount,
    this.igstAmount,
    this.cessAmount,
    this.roundOffAmount,
    this.adjustmentAmount,
    this.adjustmentAccountId,
    this.adjustmentRemarks,
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
  final int? companyId;
  final int? branchId;
  final int? locationId;
  final int? financialYearId;
  final int? documentSeriesId;
  final int? salesInvoiceId;
  final String? returnNo;
  final String? returnDate;
  final int? customerPartyId;
  final double? subtotal;
  final double? discountAmount;
  final double? taxableAmount;
  final double? cgstAmount;
  final double? sgstAmount;
  final double? igstAmount;
  final double? cessAmount;
  final double? roundOffAmount;
  final double? adjustmentAmount;
  final int? adjustmentAccountId;
  final String? adjustmentRemarks;
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

  factory SalesReturnModel.fromJson(Map<String, dynamic> json) {
    return SalesReturnModel(
      id: JsonModel.nullableInt(json['id']),
      companyId: JsonModel.nullableInt(json['company_id']),
      branchId: JsonModel.nullableInt(json['branch_id']),
      locationId: JsonModel.nullableInt(json['location_id']),
      financialYearId: JsonModel.nullableInt(json['financial_year_id']),
      documentSeriesId: JsonModel.nullableInt(json['document_series_id']),
      salesInvoiceId: JsonModel.nullableInt(json['sales_invoice_id']),
      returnNo: json['return_no']?.toString(),
      returnDate: json['return_date']?.toString(),
      customerPartyId: JsonModel.nullableInt(json['customer_party_id']),
      subtotal: JsonModel.nullableDouble(json['subtotal']),
      discountAmount: JsonModel.nullableDouble(json['discount_amount']),
      taxableAmount: JsonModel.nullableDouble(json['taxable_amount']),
      cgstAmount: JsonModel.nullableDouble(json['cgst_amount']),
      sgstAmount: JsonModel.nullableDouble(json['sgst_amount']),
      igstAmount: JsonModel.nullableDouble(json['igst_amount']),
      cessAmount: JsonModel.nullableDouble(json['cess_amount']),
      roundOffAmount: JsonModel.nullableDouble(json['round_off_amount']),
      adjustmentAmount: JsonModel.nullableDouble(json['adjustment_amount']),
      adjustmentAccountId: JsonModel.nullableInt(
        json['adjustment_account_id'],
      ),
      adjustmentRemarks: json['adjustment_remarks']?.toString(),
      totalAmount: JsonModel.nullableDouble(json['total_amount']),
      voucherId: JsonModel.nullableInt(json['voucher_id']),
      returnReason: json['return_reason']?.toString(),
      returnStatus: json['return_status']?.toString(),
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
    );
  }
  @override
  String toString() => JsonModel.combineValues([
    returnNo,
    returnDate,
    returnStatus,
  ], defaultValue: 'Sales Return');


  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (companyId != null) 'company_id': companyId,
    if (branchId != null) 'branch_id': branchId,
    if (locationId != null) 'location_id': locationId,
    if (financialYearId != null) 'financial_year_id': financialYearId,
    if (documentSeriesId != null) 'document_series_id': documentSeriesId,
    if (salesInvoiceId != null) 'sales_invoice_id': salesInvoiceId,
    if (returnNo != null) 'return_no': returnNo,
    if (returnDate != null) 'return_date': returnDate,
    if (customerPartyId != null) 'customer_party_id': customerPartyId,
    if (subtotal != null) 'subtotal': subtotal,
    if (discountAmount != null) 'discount_amount': discountAmount,
    if (taxableAmount != null) 'taxable_amount': taxableAmount,
    if (cgstAmount != null) 'cgst_amount': cgstAmount,
    if (sgstAmount != null) 'sgst_amount': sgstAmount,
    if (igstAmount != null) 'igst_amount': igstAmount,
    if (cessAmount != null) 'cess_amount': cessAmount,
    if (roundOffAmount != null) 'round_off_amount': roundOffAmount,
    if (adjustmentAmount != null) 'adjustment_amount': adjustmentAmount,
    if (adjustmentAccountId != null)
      'adjustment_account_id': adjustmentAccountId,
    if (adjustmentRemarks != null) 'adjustment_remarks': adjustmentRemarks,
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
