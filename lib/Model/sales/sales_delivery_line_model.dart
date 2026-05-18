import '../../screen.dart';

class SalesDeliveryLineModel implements JsonModel {
  const SalesDeliveryLineModel({
    this.id,
    this.salesDeliveryId,
    this.salesOrderLineId,
    this.lineNo,
    this.itemId,
    this.warehouseId,
    this.uomId,
    this.batchId,
    this.serialId,
    this.description,
    this.deliveredQty,
    this.invoicedQty,
    this.pendingInvoiceQty,
    this.rate,
    this.amount,
    this.lineStatus,
    this.remarks,
    this.createdAt,
    this.updatedAt,
    Map<String, dynamic>? raw,
  }) : _raw = raw;

  final int? id;
  final int? salesDeliveryId;
  final int? salesOrderLineId;
  final int? lineNo;
  final int? itemId;
  final int? warehouseId;
  final int? uomId;
  final int? batchId;
  final int? serialId;
  final String? description;
  final double? deliveredQty;
  final double? invoicedQty;
  final double? pendingInvoiceQty;
  final double? rate;
  final double? amount;
  final String? lineStatus;
  final String? remarks;
  final String? createdAt;
  final String? updatedAt;

  factory SalesDeliveryLineModel.fromJson(Map<String, dynamic> json) {
    return SalesDeliveryLineModel(
      id: ModelValue.nullableInt(json['id']),
      salesDeliveryId: ModelValue.nullableInt(json['sales_delivery_id']),
      salesOrderLineId: ModelValue.nullableInt(json['sales_order_line_id']),
      lineNo: ModelValue.nullableInt(json['line_no']),
      itemId: ModelValue.nullableInt(json['item_id']),
      warehouseId: ModelValue.nullableInt(json['warehouse_id']),
      uomId: ModelValue.nullableInt(json['uom_id']),
      batchId: ModelValue.nullableInt(json['batch_id']),
      serialId: ModelValue.nullableInt(json['serial_id']),
      description: json['description']?.toString(),
      deliveredQty: ModelValue.nullableDouble(json['delivered_qty']),
      invoicedQty: ModelValue.nullableDouble(json['invoiced_qty']),
      pendingInvoiceQty: ModelValue.nullableDouble(json['pending_invoice_qty']),
      rate: ModelValue.nullableDouble(json['rate']),
      amount: ModelValue.nullableDouble(json['amount']),
      lineStatus: json['line_status']?.toString(),
      remarks: json['remarks']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (salesDeliveryId != null) 'sales_delivery_id': salesDeliveryId,
    if (salesOrderLineId != null) 'sales_order_line_id': salesOrderLineId,
    if (lineNo != null) 'line_no': lineNo,
    if (itemId != null) 'item_id': itemId,
    if (warehouseId != null) 'warehouse_id': warehouseId,
    if (uomId != null) 'uom_id': uomId,
    if (batchId != null) 'batch_id': batchId,
    if (serialId != null) 'serial_id': serialId,
    if (description != null) 'description': description,
    if (deliveredQty != null) 'delivered_qty': deliveredQty,
    if (invoicedQty != null) 'invoiced_qty': invoicedQty,
    if (pendingInvoiceQty != null) 'pending_invoice_qty': pendingInvoiceQty,
    if (rate != null) 'rate': rate,
    if (amount != null) 'amount': amount,
    if (lineStatus != null) 'line_status': lineStatus,
    if (remarks != null) 'remarks': remarks,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
