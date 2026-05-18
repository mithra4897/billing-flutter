import '../../screen.dart';

class MaintenanceWorkOrderServiceModel implements JsonModel {
  const MaintenanceWorkOrderServiceModel({
    this.id,
    this.maintenanceWorkOrderId,
    this.lineNo,
    this.serviceDescription,
    this.vendorPartyId,
    this.purchaseInvoiceId,
    this.qty,
    this.rate,
    this.amount,
    this.taxCodeId,
    this.taxPercent,
    this.taxAmount,
    this.lineTotal,
    this.remarks,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final int? maintenanceWorkOrderId;
  final int? lineNo;
  final String? serviceDescription;
  final int? vendorPartyId;
  final int? purchaseInvoiceId;
  final double? qty;
  final double? rate;
  final double? amount;
  final int? taxCodeId;
  final double? taxPercent;
  final double? taxAmount;
  final double? lineTotal;
  final String? remarks;
  final String? createdAt;
  final String? updatedAt;

  factory MaintenanceWorkOrderServiceModel.fromJson(Map<String, dynamic> json) {
    return MaintenanceWorkOrderServiceModel(
      id: ModelValue.nullableInt(json['id']),
      maintenanceWorkOrderId: ModelValue.nullableInt(
        json['maintenance_work_order_id'],
      ),
      lineNo: ModelValue.nullableInt(json['line_no']),
      serviceDescription: json['service_description']?.toString(),
      vendorPartyId: ModelValue.nullableInt(json['vendor_party_id']),
      purchaseInvoiceId: ModelValue.nullableInt(json['purchase_invoice_id']),
      qty: ModelValue.nullableDouble(json['qty']),
      rate: ModelValue.nullableDouble(json['rate']),
      amount: ModelValue.nullableDouble(json['amount']),
      taxCodeId: ModelValue.nullableInt(json['tax_code_id']),
      taxPercent: ModelValue.nullableDouble(json['tax_percent']),
      taxAmount: ModelValue.nullableDouble(json['tax_amount']),
      lineTotal: ModelValue.nullableDouble(json['line_total']),
      remarks: json['remarks']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (maintenanceWorkOrderId != null)
      'maintenance_work_order_id': maintenanceWorkOrderId,
    if (lineNo != null) 'line_no': lineNo,
    if (serviceDescription != null) 'service_description': serviceDescription,
    if (vendorPartyId != null) 'vendor_party_id': vendorPartyId,
    if (purchaseInvoiceId != null) 'purchase_invoice_id': purchaseInvoiceId,
    if (qty != null) 'qty': qty,
    if (rate != null) 'rate': rate,
    if (amount != null) 'amount': amount,
    if (taxCodeId != null) 'tax_code_id': taxCodeId,
    if (taxPercent != null) 'tax_percent': taxPercent,
    if (taxAmount != null) 'tax_amount': taxAmount,
    if (lineTotal != null) 'line_total': lineTotal,
    if (remarks != null) 'remarks': remarks,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
