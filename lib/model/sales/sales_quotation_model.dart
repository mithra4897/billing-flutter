import '../../screen.dart';

class SalesQuotationModel extends JsonModel {
  const SalesQuotationModel({
    super.id,
    this.companyId,
    this.branchId,
    this.locationId,
    this.financialYearId,
    this.documentSeriesId,
    this.quotationNo,
    this.quotationDate,
    this.validUntil,
    this.customerPartyId,
    this.customerName,
    this.customer,
    this.billingAddressId,
    this.shippingAddressId,
    this.contactId,
    this.crmOpportunityId,
    this.customerReferenceNo,
    this.customerReferenceDate,
    this.priceType,
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
    this.quotationStatus,
    this.notes,
    this.termsConditions,
    this.approvedBy,
    this.approvedAt,
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
  final String? quotationNo;
  final String? quotationDate;
  final String? validUntil;
  final int? customerPartyId;
  final String? customerName;
  final Map<String, dynamic>? customer;
  final int? billingAddressId;
  final int? shippingAddressId;
  final int? contactId;
  final int? crmOpportunityId;
  final String? customerReferenceNo;
  final String? customerReferenceDate;
  final String? priceType;
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
  final String? quotationStatus;
  final String? notes;
  final String? termsConditions;
  final int? approvedBy;
  final String? approvedAt;
  final bool? isActive;
  final int? createdBy;
  final int? updatedBy;
  final String? createdAt;
  final String? updatedAt;
  final List<Map<String, dynamic>> lines;

  factory SalesQuotationModel.fromJson(Map<String, dynamic> json) {
    return SalesQuotationModel(
      id: JsonModel.nullableInt(json['id']),
      companyId: JsonModel.nullableInt(json['company_id']),
      branchId: JsonModel.nullableInt(json['branch_id']),
      locationId: JsonModel.nullableInt(json['location_id']),
      financialYearId: JsonModel.nullableInt(json['financial_year_id']),
      documentSeriesId: JsonModel.nullableInt(json['document_series_id']),
      quotationNo: json['quotation_no']?.toString(),
      quotationDate: json['quotation_date']?.toString(),
      validUntil: json['valid_until']?.toString(),
      customerPartyId: JsonModel.nullableInt(json['customer_party_id']),
      customerName: json['customer_name']?.toString(),
      customer: JsonModel.mapOf(json['customer']),
      billingAddressId: JsonModel.nullableInt(json['billing_address_id']),
      shippingAddressId: JsonModel.nullableInt(json['shipping_address_id']),
      contactId: JsonModel.nullableInt(json['contact_id']),
      crmOpportunityId: JsonModel.nullableInt(json['crm_opportunity_id']),
      customerReferenceNo: json['customer_reference_no']?.toString(),
      customerReferenceDate: json['customer_reference_date']?.toString(),
      priceType: json['price_type']?.toString(),
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
      quotationStatus: json['quotation_status']?.toString(),
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
      lines: _mapLines(json['lines']),
    );
  }
  @override
  String toString() => JsonModel.combineValues([
    quotationNo,
    quotationDate,
    currencyCode,
  ], defaultValue: 'Sales Quotation');

  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (companyId != null) 'company_id': companyId,
    if (branchId != null) 'branch_id': branchId,
    if (locationId != null) 'location_id': locationId,
    if (financialYearId != null) 'financial_year_id': financialYearId,
    if (documentSeriesId != null) 'document_series_id': documentSeriesId,
    if (quotationNo != null) 'quotation_no': quotationNo,
    if (quotationDate != null) 'quotation_date': quotationDate,
    if (validUntil != null) 'valid_until': validUntil,
    if (customerPartyId != null) 'customer_party_id': customerPartyId,
    if (customerName != null) 'customer_name': customerName,
    if (customer != null) 'customer': customer,
    if (billingAddressId != null) 'billing_address_id': billingAddressId,
    if (shippingAddressId != null) 'shipping_address_id': shippingAddressId,
    if (contactId != null) 'contact_id': contactId,
    if (crmOpportunityId != null) 'crm_opportunity_id': crmOpportunityId,
    if (customerReferenceNo != null)
      'customer_reference_no': customerReferenceNo,
    if (customerReferenceDate != null)
      'customer_reference_date': customerReferenceDate,
    if (priceType != null) 'price_type': priceType,
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
    if (quotationStatus != null) 'quotation_status': quotationStatus,
    if (notes != null) 'notes': notes,
    if (termsConditions != null) 'terms_conditions': termsConditions,
    if (approvedBy != null) 'approved_by': approvedBy,
    if (approvedAt != null) 'approved_at': approvedAt,
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
