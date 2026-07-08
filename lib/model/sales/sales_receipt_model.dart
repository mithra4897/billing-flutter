import '../../screen.dart';

class SalesReceiptModel extends JsonModel {
  const SalesReceiptModel({
    super.id,
    this.companyId,
    this.branchId,
    this.locationId,
    this.financialYearId,
    this.documentSeriesId,
    this.receiptNo,
    this.receiptDate,
    this.customerPartyId,
    this.isDirectCustomer = false,
    this.directCustomerDetails,
    this.customerName,
    this.customer,
    this.paymentMode,
    this.paymentReferenceNo,
    this.paymentReferenceDate,
    this.accountId,
    this.paidAmount,
    this.unallocatedAmount,
    this.voucherId,
    this.receiptStatus,
    this.cancelReason,
    this.notes,
    this.postedBy,
    this.postedAt,
    this.isActive,
    this.allocations = const <Map<String, dynamic>>[],
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
  final String? receiptNo;
  final String? receiptDate;
  final int? customerPartyId;
  final bool isDirectCustomer;
  final String? directCustomerDetails;
  final String? customerName;
  final Map<String, dynamic>? customer;
  final String? paymentMode;
  final String? paymentReferenceNo;
  final String? paymentReferenceDate;
  final int? accountId;
  final double? paidAmount;
  final double? unallocatedAmount;
  final int? voucherId;
  final String? receiptStatus;
  final String? cancelReason;
  final String? notes;
  final int? postedBy;
  final String? postedAt;
  final bool? isActive;
  final List<Map<String, dynamic>> allocations;
  final int? createdBy;
  final int? updatedBy;
  final String? createdAt;
  final String? updatedAt;

  factory SalesReceiptModel.fromJson(Map<String, dynamic> json) {
    return SalesReceiptModel(
      id: JsonModel.nullableInt(json['id']),
      companyId: JsonModel.nullableInt(json['company_id']),
      branchId: JsonModel.nullableInt(json['branch_id']),
      locationId: JsonModel.nullableInt(json['location_id']),
      financialYearId: JsonModel.nullableInt(json['financial_year_id']),
      documentSeriesId: JsonModel.nullableInt(json['document_series_id']),
      receiptNo: json['receipt_no']?.toString(),
      receiptDate: json['receipt_date']?.toString(),
      customerPartyId: JsonModel.nullableInt(json['customer_party_id']),
      isDirectCustomer:
          json['is_direct_customer'] == true || json['is_direct_customer'] == 1,
      directCustomerDetails: json['direct_customer_details']?.toString(),
      customerName: json['customer_name']?.toString(),
      customer: JsonModel.mapOf(json['customer']),
      paymentMode: json['payment_mode']?.toString(),
      paymentReferenceNo: json['payment_reference_no']?.toString(),
      paymentReferenceDate: json['payment_reference_date']?.toString(),
      accountId: JsonModel.nullableInt(json['account_id']),
      paidAmount: JsonModel.nullableDouble(json['paid_amount']),
      unallocatedAmount: JsonModel.nullableDouble(json['unallocated_amount']),
      voucherId: JsonModel.nullableInt(json['voucher_id']),
      receiptStatus: json['receipt_status']?.toString(),
      cancelReason: json['cancel_reason']?.toString(),
      notes: json['notes']?.toString(),
      postedBy: JsonModel.nullableInt(json['posted_by']),
      postedAt: json['posted_at']?.toString(),
      isActive: json['is_active'] == null
          ? null
          : JsonModel.boolOf(json['is_active']),
      allocations: _mapAllocations(json['allocations']),
      createdBy: JsonModel.nullableInt(json['created_by']),
      updatedBy: JsonModel.nullableInt(json['updated_by']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
  @override
  String toString() => JsonModel.combineValues([
    receiptNo,
    receiptDate,
    paymentReferenceNo,
  ], defaultValue: 'Sales Receipt');

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
    'is_direct_customer': isDirectCustomer,
    if (directCustomerDetails != null)
      'direct_customer_details': directCustomerDetails,
    if (customerPartyId != null) 'customer_party_id': customerPartyId,
    if (customerName != null) 'customer_name': customerName,
    if (customer != null) 'customer': customer,
    if (paymentMode != null) 'payment_mode': paymentMode,
    if (paymentReferenceNo != null) 'payment_reference_no': paymentReferenceNo,
    if (paymentReferenceDate != null)
      'payment_reference_date': paymentReferenceDate,
    if (accountId != null) 'account_id': accountId,
    if (paidAmount != null) 'paid_amount': paidAmount,
    if (unallocatedAmount != null) 'unallocated_amount': unallocatedAmount,
    if (voucherId != null) 'voucher_id': voucherId,
    if (receiptStatus != null) 'receipt_status': receiptStatus,
    if (cancelReason != null) 'cancel_reason': cancelReason,
    if (notes != null) 'notes': notes,
    if (postedBy != null) 'posted_by': postedBy,
    if (postedAt != null) 'posted_at': postedAt,
    if (isActive != null) 'is_active': isActive,
    if (allocations.isNotEmpty) 'allocations': allocations,
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };

  static List<Map<String, dynamic>> _mapAllocations(dynamic value) {
    if (value is! List) {
      return <Map<String, dynamic>>[];
    }

    return value
        .whereType<Map>()
        .map(
          (entry) => Map<String, dynamic>.from(
            entry.map((key, itemValue) => MapEntry(key.toString(), itemValue)),
          ),
        )
        .toList(growable: false);
  }
}
