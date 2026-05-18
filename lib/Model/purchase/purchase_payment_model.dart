import '../../screen.dart';

class PurchasePaymentModel implements JsonModel {
  const PurchasePaymentModel({
    this.id,
    this.companyId,
    this.branchId,
    this.locationId,
    this.financialYearId,
    this.documentSeriesId,
    this.paymentNo,
    this.paymentDate,
    this.supplierPartyId,
    this.paymentMode,
    this.accountId,
    this.referenceNo,
    this.referenceDate,
    this.paidAmount,
    this.unallocatedAmount,
    this.voucherId,
    this.paymentStatus,
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
  final String? paymentNo;
  final String? paymentDate;
  final int? supplierPartyId;
  final String? paymentMode;
  final int? accountId;
  final String? referenceNo;
  final String? referenceDate;
  final double? paidAmount;
  final double? unallocatedAmount;
  final int? voucherId;
  final String? paymentStatus;
  final String? notes;
  final int? postedBy;
  final String? postedAt;
  final bool? isActive;
  final int? createdBy;
  final int? updatedBy;
  final String? createdAt;
  final String? updatedAt;

  factory PurchasePaymentModel.fromJson(Map<String, dynamic> json) {
    return PurchasePaymentModel(
      id: ModelValue.nullableInt(json['id']),
      companyId: ModelValue.nullableInt(json['company_id']),
      branchId: ModelValue.nullableInt(json['branch_id']),
      locationId: ModelValue.nullableInt(json['location_id']),
      financialYearId: ModelValue.nullableInt(json['financial_year_id']),
      documentSeriesId: ModelValue.nullableInt(json['document_series_id']),
      paymentNo: json['payment_no']?.toString(),
      paymentDate: json['payment_date']?.toString(),
      supplierPartyId: ModelValue.nullableInt(json['supplier_party_id']),
      paymentMode: json['payment_mode']?.toString(),
      accountId: ModelValue.nullableInt(json['account_id']),
      referenceNo: json['reference_no']?.toString(),
      referenceDate: json['reference_date']?.toString(),
      paidAmount: ModelValue.nullableDouble(json['paid_amount']),
      unallocatedAmount: ModelValue.nullableDouble(json['unallocated_amount']),
      voucherId: ModelValue.nullableInt(json['voucher_id']),
      paymentStatus: json['payment_status']?.toString(),
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
    if (paymentNo != null) 'payment_no': paymentNo,
    if (paymentDate != null) 'payment_date': paymentDate,
    if (supplierPartyId != null) 'supplier_party_id': supplierPartyId,
    if (paymentMode != null) 'payment_mode': paymentMode,
    if (accountId != null) 'account_id': accountId,
    if (referenceNo != null) 'reference_no': referenceNo,
    if (referenceDate != null) 'reference_date': referenceDate,
    if (paidAmount != null) 'paid_amount': paidAmount,
    if (unallocatedAmount != null) 'unallocated_amount': unallocatedAmount,
    if (voucherId != null) 'voucher_id': voucherId,
    if (paymentStatus != null) 'payment_status': paymentStatus,
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
