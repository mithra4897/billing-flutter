import '../../screen.dart';

class SalesQuotationModel implements JsonModel {
  const SalesQuotationModel({
    this.id,
    this.companyId,
    this.branchId,
    this.locationId,
    this.financialYearId,
    this.documentSeriesId,
    this.quotationNo,
    this.quotationDate,
    this.validUntil,
    this.customerPartyId,
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
  });

  final int? id;
  final int? companyId;
  final int? branchId;
  final int? locationId;
  final int? financialYearId;
  final int? documentSeriesId;
  final String? quotationNo;
  final String? quotationDate;
  final String? validUntil;
  final int? customerPartyId;
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

  factory SalesQuotationModel.fromJson(Map<String, dynamic> json) {
    return SalesQuotationModel(
      id: ModelValue.nullableInt(json['id']),
      companyId: ModelValue.nullableInt(json['company_id']),
      branchId: ModelValue.nullableInt(json['branch_id']),
      locationId: ModelValue.nullableInt(json['location_id']),
      financialYearId: ModelValue.nullableInt(json['financial_year_id']),
      documentSeriesId: ModelValue.nullableInt(json['document_series_id']),
      quotationNo: json['quotation_no']?.toString(),
      quotationDate: json['quotation_date']?.toString(),
      validUntil: json['valid_until']?.toString(),
      customerPartyId: ModelValue.nullableInt(json['customer_party_id']),
      billingAddressId: ModelValue.nullableInt(json['billing_address_id']),
      shippingAddressId: ModelValue.nullableInt(json['shipping_address_id']),
      contactId: ModelValue.nullableInt(json['contact_id']),
      crmOpportunityId: ModelValue.nullableInt(json['crm_opportunity_id']),
      customerReferenceNo: json['customer_reference_no']?.toString(),
      customerReferenceDate: json['customer_reference_date']?.toString(),
      priceType: json['price_type']?.toString(),
      currencyCode: json['currency_code']?.toString(),
      exchangeRate: ModelValue.nullableDouble(json['exchange_rate']),
      subtotal: ModelValue.nullableDouble(json['subtotal']),
      discountAmount: ModelValue.nullableDouble(json['discount_amount']),
      taxableAmount: ModelValue.nullableDouble(json['taxable_amount']),
      cgstAmount: ModelValue.nullableDouble(json['cgst_amount']),
      sgstAmount: ModelValue.nullableDouble(json['sgst_amount']),
      igstAmount: ModelValue.nullableDouble(json['igst_amount']),
      cessAmount: ModelValue.nullableDouble(json['cess_amount']),
      roundOffAmount: ModelValue.nullableDouble(json['round_off_amount']),
      totalAmount: ModelValue.nullableDouble(json['total_amount']),
      quotationStatus: json['quotation_status']?.toString(),
      notes: json['notes']?.toString(),
      termsConditions: json['terms_conditions']?.toString(),
      approvedBy: ModelValue.nullableInt(json['approved_by']),
      approvedAt: json['approved_at']?.toString(),
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
    if (quotationNo != null) 'quotation_no': quotationNo,
    if (quotationDate != null) 'quotation_date': quotationDate,
    if (validUntil != null) 'valid_until': validUntil,
    if (customerPartyId != null) 'customer_party_id': customerPartyId,
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
  };
}
