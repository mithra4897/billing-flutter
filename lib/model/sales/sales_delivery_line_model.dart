import '../../screen.dart';

class SalesDeliveryLineModel extends JsonModel {
  const SalesDeliveryLineModel({
    super.id,
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
  });
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
      id: JsonModel.nullableInt(json['id']),
      salesDeliveryId: JsonModel.nullableInt(json['sales_delivery_id']),
      salesOrderLineId: JsonModel.nullableInt(json['sales_order_line_id']),
      lineNo: JsonModel.nullableInt(json['line_no']),
      itemId: JsonModel.nullableInt(json['item_id']),
      warehouseId: JsonModel.nullableInt(json['warehouse_id']),
      uomId: JsonModel.nullableInt(json['uom_id']),
      batchId: JsonModel.nullableInt(json['batch_id']),
      serialId: JsonModel.nullableInt(json['serial_id']),
      description: json['description']?.toString(),
      deliveredQty: JsonModel.nullableDouble(json['delivered_qty']),
      invoicedQty: JsonModel.nullableDouble(json['invoiced_qty']),
      pendingInvoiceQty: JsonModel.nullableDouble(json['pending_invoice_qty']),
      rate: JsonModel.nullableDouble(json['rate']),
      amount: JsonModel.nullableDouble(json['amount']),
      lineStatus: json['line_status']?.toString(),
      remarks: json['remarks']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
  @override
  String toString() => JsonModel.combineValues([
    lineNo,
    lineStatus,
  ], defaultValue: 'Sales Delivery Line');


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
