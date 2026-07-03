import '../../screen.dart';

class PurchasePaymentModel extends JsonModel {
  const PurchasePaymentModel({
    super.id,
    this.companyId,
    this.branchId,
    this.locationId,
    this.financialYearId,
    this.documentSeriesId,
    this.paymentNo,
    this.paymentDate,
    this.supplierPartyId,
    this.supplierName,
    this.supplier,
    this.paymentMode,
    this.accountId,
    this.referenceNo,
    this.referenceDate,
    this.paidAmount,
    this.unallocatedAmount,
    this.voucherId,
    this.paymentStatus,
    this.cancelReason,
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
  final String? paymentNo;
  final String? paymentDate;
  final int? supplierPartyId;
  final String? supplierName;
  final Map<String, dynamic>? supplier;
  final String? paymentMode;
  final int? accountId;
  final String? referenceNo;
  final String? referenceDate;
  final double? paidAmount;
  final double? unallocatedAmount;
  final int? voucherId;
  final String? paymentStatus;
  final String? cancelReason;
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
      id: JsonModel.nullableInt(json['id']),
      companyId: JsonModel.nullableInt(json['company_id']),
      branchId: JsonModel.nullableInt(json['branch_id']),
      locationId: JsonModel.nullableInt(json['location_id']),
      financialYearId: JsonModel.nullableInt(json['financial_year_id']),
      documentSeriesId: JsonModel.nullableInt(json['document_series_id']),
      paymentNo: json['payment_no']?.toString(),
      paymentDate: json['payment_date']?.toString(),
      supplierPartyId: JsonModel.nullableInt(json['supplier_party_id']),
      supplierName: json['supplier_name']?.toString(),
      supplier: JsonModel.mapOf(json['supplier']),
      paymentMode: json['payment_mode']?.toString(),
      accountId: JsonModel.nullableInt(json['account_id']),
      referenceNo: json['reference_no']?.toString(),
      referenceDate: json['reference_date']?.toString(),
      paidAmount: JsonModel.nullableDouble(json['paid_amount']),
      unallocatedAmount: JsonModel.nullableDouble(json['unallocated_amount']),
      voucherId: JsonModel.nullableInt(json['voucher_id']),
      paymentStatus: json['payment_status']?.toString(),
      cancelReason: json['cancel_reason']?.toString(),
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
    paymentNo,
    referenceNo,
    paymentDate,
  ], defaultValue: 'Purchase Payment');

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
    if (supplierName != null) 'supplier_name': supplierName,
    if (supplier != null) 'supplier': supplier,
    if (paymentMode != null) 'payment_mode': paymentMode,
    if (accountId != null) 'account_id': accountId,
    if (referenceNo != null) 'reference_no': referenceNo,
    if (referenceDate != null) 'reference_date': referenceDate,
    if (paidAmount != null) 'paid_amount': paidAmount,
    if (unallocatedAmount != null) 'unallocated_amount': unallocatedAmount,
    if (voucherId != null) 'voucher_id': voucherId,
    if (paymentStatus != null) 'payment_status': paymentStatus,
    if (cancelReason != null) 'cancel_reason': cancelReason,
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
