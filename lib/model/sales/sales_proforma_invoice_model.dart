import '../../screen.dart';

class SalesProformaInvoiceModel extends JsonModel {
  const SalesProformaInvoiceModel({
    super.id,
    this.companyId,
    this.branchId,
    this.locationId,
    this.financialYearId,
    this.documentSeriesId,
    this.salesQuotationId,
    this.convertedSalesInvoiceId,
    this.proformaInvoiceNo,
    this.proformaInvoiceDate,
    this.validUntil,
    this.customerPartyId,
    this.isDirectCustomer = false,
    this.directCustomerDetails,
    this.customerName,
    this.customer,
    this.quotation,
    this.billingAddressId,
    this.shippingAddressId,
    this.contactId,
    this.customerReferenceNo,
    this.customerReferenceDate,
    this.priceType,
    this.subtotal,
    this.discountAmount,
    this.taxableAmount,
    this.cgstAmount,
    this.sgstAmount,
    this.igstAmount,
    this.cessAmount,
    this.roundOffAmount,
    this.totalAmount,
    this.proformaInvoiceStatus,
    this.cancelReason,
    this.notes,
    this.termsConditions,
    this.postedBy,
    this.postedAt,
    this.convertedBy,
    this.convertedAt,
    this.isActive,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
    this.lines = const <Map<String, dynamic>>[],
  });
  final int? companyId;
  final int? branchId;
  final int? locationId;
  final int? financialYearId;
  final int? documentSeriesId;
  final int? salesQuotationId;
  final int? convertedSalesInvoiceId;
  final String? proformaInvoiceNo;
  final String? proformaInvoiceDate;
  final String? validUntil;
  final int? customerPartyId;
  final bool isDirectCustomer;
  final String? directCustomerDetails;
  final String? customerName;
  final Map<String, dynamic>? customer;
  final Map<String, dynamic>? quotation;
  final int? billingAddressId;
  final int? shippingAddressId;
  final int? contactId;
  final String? customerReferenceNo;
  final String? customerReferenceDate;
  final String? priceType;
  final double? subtotal;
  final double? discountAmount;
  final double? taxableAmount;
  final double? cgstAmount;
  final double? sgstAmount;
  final double? igstAmount;
  final double? cessAmount;
  final double? roundOffAmount;
  final double? totalAmount;
  final String? proformaInvoiceStatus;
  final String? cancelReason;
  final String? notes;
  final String? termsConditions;
  final int? postedBy;
  final String? postedAt;
  final int? convertedBy;
  final String? convertedAt;
  final bool? isActive;
  final int? createdBy;
  final int? updatedBy;
  final String? createdAt;
  final String? updatedAt;
  final List<Map<String, dynamic>> lines;

  factory SalesProformaInvoiceModel.fromJson(Map<String, dynamic> json) {
    return SalesProformaInvoiceModel(
      id: JsonModel.nullableInt(json['id']),
      companyId: JsonModel.nullableInt(json['company_id']),
      branchId: JsonModel.nullableInt(json['branch_id']),
      locationId: JsonModel.nullableInt(json['location_id']),
      financialYearId: JsonModel.nullableInt(json['financial_year_id']),
      documentSeriesId: JsonModel.nullableInt(json['document_series_id']),
      salesQuotationId: JsonModel.nullableInt(json['sales_quotation_id']),
      convertedSalesInvoiceId: JsonModel.nullableInt(
        json['converted_sales_invoice_id'],
      ),
      proformaInvoiceNo: json['proforma_no']?.toString(),
      proformaInvoiceDate: json['proforma_date']?.toString(),
      validUntil: json['valid_until']?.toString(),
      customerPartyId: JsonModel.nullableInt(json['customer_party_id']),
      isDirectCustomer: json['is_direct_customer'] == null
          ? false
          : JsonModel.boolOf(json['is_direct_customer']),
      directCustomerDetails: json['direct_customer_details']?.toString(),
      customerName: json['customer_name']?.toString(),
      customer: JsonModel.mapOf(json['customer']),
      quotation: JsonModel.mapOf(json['quotation']),
      billingAddressId: JsonModel.nullableInt(json['billing_address_id']),
      shippingAddressId: JsonModel.nullableInt(json['shipping_address_id']),
      contactId: JsonModel.nullableInt(json['contact_id']),
      customerReferenceNo: json['customer_reference_no']?.toString(),
      customerReferenceDate: json['customer_reference_date']?.toString(),
      priceType: json['price_type']?.toString(),
      subtotal: JsonModel.nullableDouble(json['subtotal']),
      discountAmount: JsonModel.nullableDouble(json['discount_amount']),
      taxableAmount: JsonModel.nullableDouble(json['taxable_amount']),
      cgstAmount: JsonModel.nullableDouble(json['cgst_amount']),
      sgstAmount: JsonModel.nullableDouble(json['sgst_amount']),
      igstAmount: JsonModel.nullableDouble(json['igst_amount']),
      cessAmount: JsonModel.nullableDouble(json['cess_amount']),
      roundOffAmount: JsonModel.nullableDouble(json['round_off_amount']),
      totalAmount: JsonModel.nullableDouble(json['total_amount']),
      proformaInvoiceStatus: json['proforma_status']?.toString(),
      cancelReason: json['cancel_reason']?.toString(),
      notes: json['notes']?.toString(),
      termsConditions: json['terms_conditions']?.toString(),
      postedBy: JsonModel.nullableInt(json['posted_by']),
      postedAt: json['posted_at']?.toString(),
      convertedBy: JsonModel.nullableInt(json['converted_by']),
      convertedAt: json['converted_at']?.toString(),
      isActive: json['is_active'] == null
          ? null
          : JsonModel.boolOf(json['is_active']),
      createdBy: JsonModel.nullableInt(json['created_by']),
      updatedBy: JsonModel.nullableInt(json['updated_by']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      lines: _mapLines(json['lines']),
    );
  }
  @override
  String toString() => JsonModel.combineValues([
    proformaInvoiceNo,
    proformaInvoiceDate,
  ], defaultValue: 'Sales Proforma Invoice');

  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (companyId != null) 'company_id': companyId,
    if (branchId != null) 'branch_id': branchId,
    if (locationId != null) 'location_id': locationId,
    if (financialYearId != null) 'financial_year_id': financialYearId,
    if (documentSeriesId != null) 'document_series_id': documentSeriesId,
    if (salesQuotationId != null) 'sales_quotation_id': salesQuotationId,
    if (convertedSalesInvoiceId != null)
      'converted_sales_invoice_id': convertedSalesInvoiceId,
    if (proformaInvoiceNo != null) 'proforma_no': proformaInvoiceNo,
    if (proformaInvoiceDate != null) 'proforma_date': proformaInvoiceDate,
    if (validUntil != null) 'valid_until': validUntil,
    if (customerPartyId != null) 'customer_party_id': customerPartyId,
    'is_direct_customer': isDirectCustomer,
    if (directCustomerDetails != null)
      'direct_customer_details': directCustomerDetails,
    if (customerName != null) 'customer_name': customerName,
    if (customer != null) 'customer': customer,
    if (quotation != null) 'quotation': quotation,
    if (billingAddressId != null) 'billing_address_id': billingAddressId,
    if (shippingAddressId != null) 'shipping_address_id': shippingAddressId,
    if (contactId != null) 'contact_id': contactId,
    if (customerReferenceNo != null)
      'customer_reference_no': customerReferenceNo,
    if (customerReferenceDate != null)
      'customer_reference_date': customerReferenceDate,
    if (priceType != null) 'price_type': priceType,
    if (subtotal != null) 'subtotal': subtotal,
    if (discountAmount != null) 'discount_amount': discountAmount,
    if (taxableAmount != null) 'taxable_amount': taxableAmount,
    if (cgstAmount != null) 'cgst_amount': cgstAmount,
    if (sgstAmount != null) 'sgst_amount': sgstAmount,
    if (igstAmount != null) 'igst_amount': igstAmount,
    if (cessAmount != null) 'cess_amount': cessAmount,
    if (roundOffAmount != null) 'round_off_amount': roundOffAmount,
    if (totalAmount != null) 'total_amount': totalAmount,
    if (proformaInvoiceStatus != null) 'proforma_status': proformaInvoiceStatus,
    if (cancelReason != null) 'cancel_reason': cancelReason,
    if (notes != null) 'notes': notes,
    if (termsConditions != null) 'terms_conditions': termsConditions,
    if (postedBy != null) 'posted_by': postedBy,
    if (postedAt != null) 'posted_at': postedAt,
    if (convertedBy != null) 'converted_by': convertedBy,
    if (convertedAt != null) 'converted_at': convertedAt,
    if (isActive != null) 'is_active': isActive,
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
    if (lines.isNotEmpty) 'lines': lines,
  };

  static List<Map<String, dynamic>> _mapLines(dynamic value) {
    if (value is! List) {
      return <Map<String, dynamic>>[];
    }

    return value.whereType<Map<String, dynamic>>().toList(growable: false);
  }
}
