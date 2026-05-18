import '../../screen.dart';

class PurchaseReceiptLineModel implements JsonModel {
  const PurchaseReceiptLineModel({
    this.id,
    this.purchaseReceiptId,
    this.purchaseOrderLineId,
    this.lineNo,
    this.itemId,
    this.warehouseId,
    this.uomId,
    this.batchId,
    this.serialId,
    this.description,
    this.receivedQty,
    this.acceptedQty,
    this.rejectedQty,
    this.invoicedQty,
    this.pendingInvoiceQty,
    this.rate,
    this.amount,
    this.qualityStatus,
    this.lineStatus,
    this.remarks,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final int? purchaseReceiptId;
  final int? purchaseOrderLineId;
  final int? lineNo;
  final int? itemId;
  final int? warehouseId;
  final int? uomId;
  final int? batchId;
  final int? serialId;
  final String? description;
  final double? receivedQty;
  final double? acceptedQty;
  final double? rejectedQty;
  final double? invoicedQty;
  final double? pendingInvoiceQty;
  final double? rate;
  final double? amount;
  final String? qualityStatus;
  final String? lineStatus;
  final String? remarks;
  final String? createdAt;
  final String? updatedAt;

  factory PurchaseReceiptLineModel.fromJson(Map<String, dynamic> json) {
    return PurchaseReceiptLineModel(
      id: ModelValue.nullableInt(json['id']),
      purchaseReceiptId: ModelValue.nullableInt(json['purchase_receipt_id']),
      purchaseOrderLineId: ModelValue.nullableInt(
        json['purchase_order_line_id'],
      ),
      lineNo: ModelValue.nullableInt(json['line_no']),
      itemId: ModelValue.nullableInt(json['item_id']),
      warehouseId: ModelValue.nullableInt(json['warehouse_id']),
      uomId: ModelValue.nullableInt(json['uom_id']),
      batchId: ModelValue.nullableInt(json['batch_id']),
      serialId: ModelValue.nullableInt(json['serial_id']),
      description: json['description']?.toString(),
      receivedQty: ModelValue.nullableDouble(json['received_qty']),
      acceptedQty: ModelValue.nullableDouble(json['accepted_qty']),
      rejectedQty: ModelValue.nullableDouble(json['rejected_qty']),
      invoicedQty: ModelValue.nullableDouble(json['invoiced_qty']),
      pendingInvoiceQty: ModelValue.nullableDouble(json['pending_invoice_qty']),
      rate: ModelValue.nullableDouble(json['rate']),
      amount: ModelValue.nullableDouble(json['amount']),
      qualityStatus: json['quality_status']?.toString(),
      lineStatus: json['line_status']?.toString(),
      remarks: json['remarks']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (purchaseReceiptId != null) 'purchase_receipt_id': purchaseReceiptId,
    if (purchaseOrderLineId != null)
      'purchase_order_line_id': purchaseOrderLineId,
    if (lineNo != null) 'line_no': lineNo,
    if (itemId != null) 'item_id': itemId,
    if (warehouseId != null) 'warehouse_id': warehouseId,
    if (uomId != null) 'uom_id': uomId,
    if (batchId != null) 'batch_id': batchId,
    if (serialId != null) 'serial_id': serialId,
    if (description != null) 'description': description,
    if (receivedQty != null) 'received_qty': receivedQty,
    if (acceptedQty != null) 'accepted_qty': acceptedQty,
    if (rejectedQty != null) 'rejected_qty': rejectedQty,
    if (invoicedQty != null) 'invoiced_qty': invoicedQty,
    if (pendingInvoiceQty != null) 'pending_invoice_qty': pendingInvoiceQty,
    if (rate != null) 'rate': rate,
    if (amount != null) 'amount': amount,
    if (qualityStatus != null) 'quality_status': qualityStatus,
    if (lineStatus != null) 'line_status': lineStatus,
    if (remarks != null) 'remarks': remarks,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
