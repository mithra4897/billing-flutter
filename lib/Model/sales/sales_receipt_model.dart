import '../../screen.dart';

class SalesReceiptModel implements JsonModel {
  const SalesReceiptModel({
    this.id,
    this.companyId,
    this.branchId,
    this.locationId,
    this.financialYearId,
    this.documentSeriesId,
    this.receiptNo,
    this.receiptDate,
    this.customerPartyId,
    this.paymentMode,
    this.paymentReferenceNo,
    this.paymentReferenceDate,
    this.accountId,
    this.paidAmount,
    this.unallocatedAmount,
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
  final String? receiptNo;
  final String? receiptDate;
  final int? customerPartyId;
  final String? paymentMode;
  final String? paymentReferenceNo;
  final String? paymentReferenceDate;
  final int? accountId;
  final double? paidAmount;
  final double? unallocatedAmount;
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

  factory SalesReceiptModel.fromJson(Map<String, dynamic> json) {
    return SalesReceiptModel(
      id: ModelValue.nullableInt(json['id']),
      companyId: ModelValue.nullableInt(json['company_id']),
      branchId: ModelValue.nullableInt(json['branch_id']),
      locationId: ModelValue.nullableInt(json['location_id']),
      financialYearId: ModelValue.nullableInt(json['financial_year_id']),
      documentSeriesId: ModelValue.nullableInt(json['document_series_id']),
      receiptNo: json['receipt_no']?.toString(),
      receiptDate: json['receipt_date']?.toString(),
      customerPartyId: ModelValue.nullableInt(json['customer_party_id']),
      paymentMode: json['payment_mode']?.toString(),
      paymentReferenceNo: json['payment_reference_no']?.toString(),
      paymentReferenceDate: json['payment_reference_date']?.toString(),
      accountId: ModelValue.nullableInt(json['account_id']),
      paidAmount: ModelValue.nullableDouble(json['paid_amount']),
      unallocatedAmount: ModelValue.nullableDouble(json['unallocated_amount']),
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
    if (receiptNo != null) 'receipt_no': receiptNo,
    if (receiptDate != null) 'receipt_date': receiptDate,
    if (customerPartyId != null) 'customer_party_id': customerPartyId,
    if (paymentMode != null) 'payment_mode': paymentMode,
    if (paymentReferenceNo != null) 'payment_reference_no': paymentReferenceNo,
    if (paymentReferenceDate != null)
      'payment_reference_date': paymentReferenceDate,
    if (accountId != null) 'account_id': accountId,
    if (paidAmount != null) 'paid_amount': paidAmount,
    if (unallocatedAmount != null) 'unallocated_amount': unallocatedAmount,
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
