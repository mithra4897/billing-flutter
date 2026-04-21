import '../accounting/voucher_model.dart';
import 'sales_invoice_line_model.dart';

class SalesInvoiceModel {
  const SalesInvoiceModel({
    required this.id,
    required this.companyId,
    required this.branchId,
    required this.locationId,
    required this.financialYearId,
    required this.customerPartyId,
    required this.invoiceDate,
    this.documentSeriesId,
    this.salesOrderId,
    this.salesDeliveryId,
    this.invoiceNo,
    this.dueDate,
    this.billingAddressId,
    this.shippingAddressId,
    this.contactId,
    this.currencyCode,
    this.exchangeRate,
    this.roundOffMethod,
    this.roundOffPrecision,
    this.roundOffAmount,
    this.adjustmentAmount,
    this.adjustmentAccountId,
    this.adjustmentRemarks,
    this.totalAmount,
    this.invoiceStatus,
    this.notes,
    this.termsConditions,
    this.customerReferenceNo,
    this.customerReferenceDate,
    this.isActive,
    this.lines = const [],
    this.voucher,
    this.raw,
  });

  final int id;
  final int companyId;
  final int branchId;
  final int locationId;
  final int financialYearId;
  final int customerPartyId;
  final String invoiceDate;
  final int? documentSeriesId;
  final int? salesOrderId;
  final int? salesDeliveryId;
  final String? invoiceNo;
  final String? dueDate;
  final int? billingAddressId;
  final int? shippingAddressId;
  final int? contactId;
  final String? currencyCode;
  final double? exchangeRate;
  final String? roundOffMethod;
  final double? roundOffPrecision;
  final double? roundOffAmount;
  final double? adjustmentAmount;
  final int? adjustmentAccountId;
  final String? adjustmentRemarks;
  final double? totalAmount;
  final String? invoiceStatus;
  final String? notes;
  final String? termsConditions;
  final String? customerReferenceNo;
  final String? customerReferenceDate;
  final bool? isActive;
  final List<SalesInvoiceLineModel> lines;
  final VoucherModel? voucher;
  final Map<String, dynamic>? raw;

  factory SalesInvoiceModel.fromJson(Map<String, dynamic> json) {
    return SalesInvoiceModel(
      id: _parseInt(json['id']),
      companyId: _parseInt(json['company_id']),
      branchId: _parseInt(json['branch_id']),
      locationId: _parseInt(json['location_id']),
      financialYearId: _parseInt(json['financial_year_id']),
      customerPartyId: _parseInt(json['customer_party_id']),
      invoiceDate: json['invoice_date']?.toString() ?? '',
      documentSeriesId: _nullableInt(json['document_series_id']),
      salesOrderId: _nullableInt(json['sales_order_id']),
      salesDeliveryId: _nullableInt(json['sales_delivery_id']),
      invoiceNo: json['invoice_no']?.toString(),
      dueDate: json['due_date']?.toString(),
      billingAddressId: _nullableInt(json['billing_address_id']),
      shippingAddressId: _nullableInt(json['shipping_address_id']),
      contactId: _nullableInt(json['contact_id']),
      currencyCode: json['currency_code']?.toString(),
      exchangeRate: _nullableDouble(json['exchange_rate']),
      roundOffMethod: json['round_off_method']?.toString(),
      roundOffPrecision: _nullableDouble(json['round_off_precision']),
      roundOffAmount: _nullableDouble(json['round_off_amount']),
      adjustmentAmount: _nullableDouble(json['adjustment_amount']),
      adjustmentAccountId: _nullableInt(json['adjustment_account_id']),
      adjustmentRemarks: json['adjustment_remarks']?.toString(),
      totalAmount: _nullableDouble(json['total_amount']),
      invoiceStatus: json['invoice_status']?.toString(),
      notes: json['notes']?.toString(),
      termsConditions: json['terms_conditions']?.toString(),
      customerReferenceNo: json['customer_reference_no']?.toString(),
      customerReferenceDate: json['customer_reference_date']?.toString(),
      isActive: json['is_active'] == null
          ? null
          : json['is_active'] == true || json['is_active'] == 1,
      lines: _mapLines(json['lines']),
      voucher: json['voucher'] is Map<String, dynamic>
          ? VoucherModel.fromJson(json['voucher'] as Map<String, dynamic>)
          : null,
      raw: json,
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'company_id': companyId,
      'branch_id': branchId,
      'location_id': locationId,
      'financial_year_id': financialYearId,
      if (documentSeriesId != null) 'document_series_id': documentSeriesId,
      if (salesOrderId != null) 'sales_order_id': salesOrderId,
      if (salesDeliveryId != null) 'sales_delivery_id': salesDeliveryId,
      if (invoiceNo != null) 'invoice_no': invoiceNo,
      'invoice_date': invoiceDate,
      if (dueDate != null) 'due_date': dueDate,
      'customer_party_id': customerPartyId,
      if (billingAddressId != null) 'billing_address_id': billingAddressId,
      if (shippingAddressId != null) 'shipping_address_id': shippingAddressId,
      if (contactId != null) 'contact_id': contactId,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (exchangeRate != null) 'exchange_rate': exchangeRate,
      if (roundOffMethod != null) 'round_off_method': roundOffMethod,
      if (roundOffPrecision != null) 'round_off_precision': roundOffPrecision,
      if (roundOffAmount != null) 'round_off_amount': roundOffAmount,
      if (adjustmentAmount != null) 'adjustment_amount': adjustmentAmount,
      if (adjustmentAccountId != null)
        'adjustment_account_id': adjustmentAccountId,
      if (adjustmentRemarks != null) 'adjustment_remarks': adjustmentRemarks,
      if (notes != null) 'notes': notes,
      if (termsConditions != null) 'terms_conditions': termsConditions,
      if (customerReferenceNo != null && customerReferenceNo!.isNotEmpty)
        'customer_reference_no': customerReferenceNo,
      if (customerReferenceDate != null &&
          customerReferenceDate!.isNotEmpty)
        'customer_reference_date': customerReferenceDate,
      if (isActive != null) 'is_active': isActive,
      'lines': lines.map((line) => line.toJson()).toList(growable: false),
    };
  }

  static List<SalesInvoiceLineModel> _mapLines(dynamic value) {
    if (value is! List) {
      return <SalesInvoiceLineModel>[];
    }

    return value
        .whereType<Map<String, dynamic>>()
        .map(SalesInvoiceLineModel.fromJson)
        .toList(growable: false);
  }

  static int _parseInt(dynamic value) =>
      int.tryParse(value?.toString() ?? '') ?? 0;

  static int? _nullableInt(dynamic value) =>
      int.tryParse(value?.toString() ?? '');

  static double? _nullableDouble(dynamic value) =>
      double.tryParse(value?.toString() ?? '');
}
