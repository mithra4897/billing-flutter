import '../../screen.dart';

class PurchaseInvoiceModel extends JsonModel {
  const PurchaseInvoiceModel({
    required super.id,
    required this.companyId,
    required this.branchId,
    required this.locationId,
    required this.financialYearId,
    required this.supplierPartyId,
    required this.invoiceDate,
    this.documentSeriesId,
    this.purchaseOrderId,
    this.purchaseReceiptId,
    this.invoiceNo,
    this.supplierName,
    this.supplier,
    this.purchaseOrderNo,
    this.purchaseReceiptNo,
    this.dueDate,
    this.supplierReferenceNo,
    this.supplierReferenceDate,
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
    this.balanceAmount,
    this.isActive = true,
    this.notes,
    this.termsConditions,
    this.lines = const [],
    this.voucher,
  });
  final int companyId;
  final int branchId;
  final int locationId;
  final int financialYearId;
  final int supplierPartyId;
  final String invoiceDate;
  final int? documentSeriesId;
  final int? purchaseOrderId;
  final int? purchaseReceiptId;
  final String? invoiceNo;
  final String? supplierName;
  final Map<String, dynamic>? supplier;
  final String? purchaseOrderNo;
  final String? purchaseReceiptNo;
  final String? dueDate;
  final String? supplierReferenceNo;
  final String? supplierReferenceDate;
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
  final double? balanceAmount;
  final bool isActive;
  final String? notes;
  final String? termsConditions;
  final List<PurchaseInvoiceLineModel> lines;
  final VoucherModel? voucher;

  factory PurchaseInvoiceModel.fromJson(Map<String, dynamic> json) {
    return PurchaseInvoiceModel(
      id: _parseInt(json['id']),
      companyId: _parseInt(json['company_id']),
      branchId: _parseInt(json['branch_id']),
      locationId: _parseInt(json['location_id']),
      financialYearId: _parseInt(json['financial_year_id']),
      supplierPartyId: _parseInt(json['supplier_party_id']),
      invoiceDate: json['invoice_date']?.toString() ?? '',
      documentSeriesId: _nullableInt(json['document_series_id']),
      purchaseOrderId: _nullableInt(json['purchase_order_id']),
      purchaseReceiptId: _nullableInt(json['purchase_receipt_id']),
      invoiceNo: json['invoice_no']?.toString(),
      supplierName: json['supplier_name']?.toString(),
      supplier: JsonModel.mapOf(json['supplier']),
      purchaseOrderNo: json['purchase_order_no']?.toString(),
      purchaseReceiptNo: json['purchase_receipt_no']?.toString(),
      dueDate: json['due_date']?.toString(),
      supplierReferenceNo: json['supplier_reference_no']?.toString(),
      supplierReferenceDate: json['supplier_reference_date']?.toString(),
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
      balanceAmount: _nullableDouble(json['balance_amount']),
      isActive: json['is_active'] == null
          ? true
          : json['is_active'] == true || json['is_active'] == 1,
      notes: json['notes']?.toString(),
      termsConditions: json['terms_conditions']?.toString(),
      lines: _mapLines(json['lines']),
      voucher: json['voucher'] is Map<String, dynamic>
          ? VoucherModel.fromJson(json['voucher'] as Map<String, dynamic>)
          : null,
    );
  }
  @override
  String toString() => invoiceNo ?? 'Purchase Invoice';

  Map<String, dynamic> toCreateJson() {
    return {
      'company_id': companyId,
      'branch_id': branchId,
      'location_id': locationId,
      'financial_year_id': financialYearId,
      if (documentSeriesId != null) 'document_series_id': documentSeriesId,
      if (purchaseOrderId != null) 'purchase_order_id': purchaseOrderId,
      if (purchaseReceiptId != null) 'purchase_receipt_id': purchaseReceiptId,
      if (invoiceNo != null) 'invoice_no': invoiceNo,
      if (supplierName != null) 'supplier_name': supplierName,
      if (supplier != null) 'supplier': supplier,
      if (purchaseOrderNo != null) 'purchase_order_no': purchaseOrderNo,
      if (purchaseReceiptNo != null) 'purchase_receipt_no': purchaseReceiptNo,
      'invoice_date': invoiceDate,
      if (dueDate != null) 'due_date': dueDate,
      if (supplierReferenceNo != null)
        'supplier_reference_no': supplierReferenceNo,
      if (supplierReferenceDate != null)
        'supplier_reference_date': supplierReferenceDate,
      'supplier_party_id': supplierPartyId,
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
      'is_active': isActive,
      if (notes != null) 'notes': notes,
      if (termsConditions != null) 'terms_conditions': termsConditions,
      'lines': lines.map((line) => line.toJson()).toList(growable: false),
    };
  }

  @override
  Map<String, dynamic> toJson() => {
    if (id != 0) 'id': id,
    ...toCreateJson(),
    if (totalAmount != null) 'total_amount': totalAmount,
    if (invoiceStatus != null) 'invoice_status': invoiceStatus,
    if (balanceAmount != null) 'balance_amount': balanceAmount,
    if (voucher != null) 'voucher': voucher!.toJson(),
  };

  static List<PurchaseInvoiceLineModel> _mapLines(dynamic value) {
    if (value is! List) {
      return <PurchaseInvoiceLineModel>[];
    }

    return value
        .whereType<Map<String, dynamic>>()
        .map(PurchaseInvoiceLineModel.fromJson)
        .toList(growable: false);
  }

  static int _parseInt(dynamic value) =>
      int.tryParse(value?.toString() ?? '') ?? 0;

  static int? _nullableInt(dynamic value) =>
      int.tryParse(value?.toString() ?? '');

  static double? _nullableDouble(dynamic value) =>
      double.tryParse(value?.toString() ?? '');
}
