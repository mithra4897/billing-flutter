import '../../screen.dart';

class PurchaseOrderModel extends JsonModel {
  const PurchaseOrderModel({
    super.id,
    this.companyId,
    this.branchId,
    this.locationId,
    this.financialYearId,
    this.documentSeriesId,
    this.purchaseRequisitionId,
    this.orderNo,
    this.orderDate,
    this.expectedReceiptDate,
    this.supplierPartyId,
    this.billingAddressId,
    this.shippingAddressId,
    this.contactId,
    this.supplierReferenceNo,
    this.supplierReferenceDate,
    this.currencyCode,
    this.exchangeRate,
    this.subtotal,
    this.discountAmount,
    this.taxableAmount,
    this.cgstAmount,
    this.sgstAmount,
    this.igstAmount,
    this.cessAmount,
    this.roundOffAmount,
    this.totalAmount,
    this.orderStatus,
    this.notes,
    this.termsConditions,
    this.approvedBy,
    this.approvedAt,
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
  final int? purchaseRequisitionId;
  final String? orderNo;
  final String? orderDate;
  final String? expectedReceiptDate;
  final int? supplierPartyId;
  final int? billingAddressId;
  final int? shippingAddressId;
  final int? contactId;
  final String? supplierReferenceNo;
  final String? supplierReferenceDate;
  final String? currencyCode;
  final double? exchangeRate;
  final double? subtotal;
  final double? discountAmount;
  final double? taxableAmount;
  final double? cgstAmount;
  final double? sgstAmount;
  final double? igstAmount;
  final double? cessAmount;
  final double? roundOffAmount;
  final double? totalAmount;
  final String? orderStatus;
  final String? notes;
  final String? termsConditions;
  final int? approvedBy;
  final String? approvedAt;
  final bool? isActive;
  final int? createdBy;
  final int? updatedBy;
  final String? createdAt;
  final String? updatedAt;

  factory PurchaseOrderModel.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderModel(
      id: JsonModel.nullableInt(json['id']),
      companyId: JsonModel.nullableInt(json['company_id']),
      branchId: JsonModel.nullableInt(json['branch_id']),
      locationId: JsonModel.nullableInt(json['location_id']),
      financialYearId: JsonModel.nullableInt(json['financial_year_id']),
      documentSeriesId: JsonModel.nullableInt(json['document_series_id']),
      purchaseRequisitionId: JsonModel.nullableInt(
        json['purchase_requisition_id'],
      ),
      orderNo: json['order_no']?.toString(),
      orderDate: json['order_date']?.toString(),
      expectedReceiptDate: json['expected_receipt_date']?.toString(),
      supplierPartyId: JsonModel.nullableInt(json['supplier_party_id']),
      billingAddressId: JsonModel.nullableInt(json['billing_address_id']),
      shippingAddressId: JsonModel.nullableInt(json['shipping_address_id']),
      contactId: JsonModel.nullableInt(json['contact_id']),
      supplierReferenceNo: json['supplier_reference_no']?.toString(),
      supplierReferenceDate: json['supplier_reference_date']?.toString(),
      currencyCode: json['currency_code']?.toString(),
      exchangeRate: JsonModel.nullableDouble(json['exchange_rate']),
      subtotal: JsonModel.nullableDouble(json['subtotal']),
      discountAmount: JsonModel.nullableDouble(json['discount_amount']),
      taxableAmount: JsonModel.nullableDouble(json['taxable_amount']),
      cgstAmount: JsonModel.nullableDouble(json['cgst_amount']),
      sgstAmount: JsonModel.nullableDouble(json['sgst_amount']),
      igstAmount: JsonModel.nullableDouble(json['igst_amount']),
      cessAmount: JsonModel.nullableDouble(json['cess_amount']),
      roundOffAmount: JsonModel.nullableDouble(json['round_off_amount']),
      totalAmount: JsonModel.nullableDouble(json['total_amount']),
      orderStatus: json['order_status']?.toString(),
      notes: json['notes']?.toString(),
      termsConditions: json['terms_conditions']?.toString(),
      approvedBy: JsonModel.nullableInt(json['approved_by']),
      approvedAt: json['approved_at']?.toString(),
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
  String toString() => 'Purchase Order';


  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (companyId != null) 'company_id': companyId,
    if (branchId != null) 'branch_id': branchId,
    if (locationId != null) 'location_id': locationId,
    if (financialYearId != null) 'financial_year_id': financialYearId,
    if (documentSeriesId != null) 'document_series_id': documentSeriesId,
    if (purchaseRequisitionId != null)
      'purchase_requisition_id': purchaseRequisitionId,
    if (orderNo != null) 'order_no': orderNo,
    if (orderDate != null) 'order_date': orderDate,
    if (expectedReceiptDate != null)
      'expected_receipt_date': expectedReceiptDate,
    if (supplierPartyId != null) 'supplier_party_id': supplierPartyId,
    if (billingAddressId != null) 'billing_address_id': billingAddressId,
    if (shippingAddressId != null) 'shipping_address_id': shippingAddressId,
    if (contactId != null) 'contact_id': contactId,
    if (supplierReferenceNo != null)
      'supplier_reference_no': supplierReferenceNo,
    if (supplierReferenceDate != null)
      'supplier_reference_date': supplierReferenceDate,
    if (currencyCode != null) 'currency_code': currencyCode,
    if (exchangeRate != null) 'exchange_rate': exchangeRate,
    if (subtotal != null) 'subtotal': subtotal,
    if (discountAmount != null) 'discount_amount': discountAmount,
    if (taxableAmount != null) 'taxable_amount': taxableAmount,
    if (cgstAmount != null) 'cgst_amount': cgstAmount,
    if (sgstAmount != null) 'sgst_amount': sgstAmount,
    if (igstAmount != null) 'igst_amount': igstAmount,
    if (cessAmount != null) 'cess_amount': cessAmount,
    if (roundOffAmount != null) 'round_off_amount': roundOffAmount,
    if (totalAmount != null) 'total_amount': totalAmount,
    if (orderStatus != null) 'order_status': orderStatus,
    if (notes != null) 'notes': notes,
    if (termsConditions != null) 'terms_conditions': termsConditions,
    if (approvedBy != null) 'approved_by': approvedBy,
    if (approvedAt != null) 'approved_at': approvedAt,
    if (isActive != null) 'is_active': isActive,
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
