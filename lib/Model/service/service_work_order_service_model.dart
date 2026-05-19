import '../../screen.dart';

class ServiceWorkOrderServiceModel extends JsonModel {
  const ServiceWorkOrderServiceModel({
    super.id,
    this.serviceWorkOrderId,
    this.lineNo,
    this.serviceDescription,
    this.chargeType,
    this.vendorPartyId,
    this.purchaseInvoiceId,
    this.qty,
    this.rate,
    this.amount,
    this.warrantyCovered,
    this.chargeableToCustomer,
    this.taxCodeId,
    this.taxPercent,
    this.taxAmount,
    this.lineTotal,
    this.remarks,
    this.createdAt,
    this.updatedAt,
  });
  final int? serviceWorkOrderId;
  final int? lineNo;
  final String? serviceDescription;
  final String? chargeType;
  final int? vendorPartyId;
  final int? purchaseInvoiceId;
  final double? qty;
  final double? rate;
  final double? amount;
  final bool? warrantyCovered;
  final bool? chargeableToCustomer;
  final int? taxCodeId;
  final double? taxPercent;
  final double? taxAmount;
  final double? lineTotal;
  final String? remarks;
  final String? createdAt;
  final String? updatedAt;

  factory ServiceWorkOrderServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceWorkOrderServiceModel(
      id: JsonModel.nullableInt(json['id']),
      serviceWorkOrderId: JsonModel.nullableInt(json['service_work_order_id']),
      lineNo: JsonModel.nullableInt(json['line_no']),
      serviceDescription: json['service_description']?.toString(),
      chargeType: json['charge_type']?.toString(),
      vendorPartyId: JsonModel.nullableInt(json['vendor_party_id']),
      purchaseInvoiceId: JsonModel.nullableInt(json['purchase_invoice_id']),
      qty: JsonModel.nullableDouble(json['qty']),
      rate: JsonModel.nullableDouble(json['rate']),
      amount: JsonModel.nullableDouble(json['amount']),
      warrantyCovered: json['warranty_covered'] == null
          ? null
          : JsonModel.boolOf(json['warranty_covered']),
      chargeableToCustomer: json['chargeable_to_customer'] == null
          ? null
          : JsonModel.boolOf(json['chargeable_to_customer']),
      taxCodeId: JsonModel.nullableInt(json['tax_code_id']),
      taxPercent: JsonModel.nullableDouble(json['tax_percent']),
      taxAmount: JsonModel.nullableDouble(json['tax_amount']),
      lineTotal: JsonModel.nullableDouble(json['line_total']),
      remarks: json['remarks']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
  @override
  String toString() => JsonModel.combineValues([
    serviceDescription,
    lineNo,
    chargeType,
  ], defaultValue: 'Service Work Order Service');


  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (serviceWorkOrderId != null) 'service_work_order_id': serviceWorkOrderId,
    if (lineNo != null) 'line_no': lineNo,
    if (serviceDescription != null) 'service_description': serviceDescription,
    if (chargeType != null) 'charge_type': chargeType,
    if (vendorPartyId != null) 'vendor_party_id': vendorPartyId,
    if (purchaseInvoiceId != null) 'purchase_invoice_id': purchaseInvoiceId,
    if (qty != null) 'qty': qty,
    if (rate != null) 'rate': rate,
    if (amount != null) 'amount': amount,
    if (warrantyCovered != null) 'warranty_covered': warrantyCovered,
    if (chargeableToCustomer != null)
      'chargeable_to_customer': chargeableToCustomer,
    if (taxCodeId != null) 'tax_code_id': taxCodeId,
    if (taxPercent != null) 'tax_percent': taxPercent,
    if (taxAmount != null) 'tax_amount': taxAmount,
    if (lineTotal != null) 'line_total': lineTotal,
    if (remarks != null) 'remarks': remarks,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
