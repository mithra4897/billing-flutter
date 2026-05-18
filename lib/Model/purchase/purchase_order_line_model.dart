import '../../screen.dart';

class PurchaseOrderLineModel implements JsonModel {
  const PurchaseOrderLineModel({
    this.id,
    this.purchaseOrderId,
    this.purchaseRequisitionLineId,
    this.lineNo,
    this.itemId,
    this.warehouseId,
    this.uomId,
    this.description,
    this.orderedQty,
    this.receivedQty,
    this.invoicedQty,
    this.pendingQty,
    this.rate,
    this.discountPercent,
    this.discountAmount,
    this.grossAmount,
    this.taxableAmount,
    this.taxCodeId,
    this.taxPercent,
    this.cgstAmount,
    this.sgstAmount,
    this.igstAmount,
    this.cessAmount,
    this.lineTotal,
    this.lineStatus,
    this.remarks,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final int? purchaseOrderId;
  final int? purchaseRequisitionLineId;
  final int? lineNo;
  final int? itemId;
  final int? warehouseId;
  final int? uomId;
  final String? description;
  final double? orderedQty;
  final double? receivedQty;
  final double? invoicedQty;
  final double? pendingQty;
  final double? rate;
  final double? discountPercent;
  final double? discountAmount;
  final double? grossAmount;
  final double? taxableAmount;
  final int? taxCodeId;
  final double? taxPercent;
  final double? cgstAmount;
  final double? sgstAmount;
  final double? igstAmount;
  final double? cessAmount;
  final double? lineTotal;
  final String? lineStatus;
  final String? remarks;
  final String? createdAt;
  final String? updatedAt;

  factory PurchaseOrderLineModel.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderLineModel(
      id: ModelValue.nullableInt(json['id']),
      purchaseOrderId: ModelValue.nullableInt(json['purchase_order_id']),
      purchaseRequisitionLineId: ModelValue.nullableInt(
        json['purchase_requisition_line_id'],
      ),
      lineNo: ModelValue.nullableInt(json['line_no']),
      itemId: ModelValue.nullableInt(json['item_id']),
      warehouseId: ModelValue.nullableInt(json['warehouse_id']),
      uomId: ModelValue.nullableInt(json['uom_id']),
      description: json['description']?.toString(),
      orderedQty: ModelValue.nullableDouble(json['ordered_qty']),
      receivedQty: ModelValue.nullableDouble(json['received_qty']),
      invoicedQty: ModelValue.nullableDouble(json['invoiced_qty']),
      pendingQty: ModelValue.nullableDouble(json['pending_qty']),
      rate: ModelValue.nullableDouble(json['rate']),
      discountPercent: ModelValue.nullableDouble(json['discount_percent']),
      discountAmount: ModelValue.nullableDouble(json['discount_amount']),
      grossAmount: ModelValue.nullableDouble(json['gross_amount']),
      taxableAmount: ModelValue.nullableDouble(json['taxable_amount']),
      taxCodeId: ModelValue.nullableInt(json['tax_code_id']),
      taxPercent: ModelValue.nullableDouble(json['tax_percent']),
      cgstAmount: ModelValue.nullableDouble(json['cgst_amount']),
      sgstAmount: ModelValue.nullableDouble(json['sgst_amount']),
      igstAmount: ModelValue.nullableDouble(json['igst_amount']),
      cessAmount: ModelValue.nullableDouble(json['cess_amount']),
      lineTotal: ModelValue.nullableDouble(json['line_total']),
      lineStatus: json['line_status']?.toString(),
      remarks: json['remarks']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (purchaseOrderId != null) 'purchase_order_id': purchaseOrderId,
    if (purchaseRequisitionLineId != null)
      'purchase_requisition_line_id': purchaseRequisitionLineId,
    if (lineNo != null) 'line_no': lineNo,
    if (itemId != null) 'item_id': itemId,
    if (warehouseId != null) 'warehouse_id': warehouseId,
    if (uomId != null) 'uom_id': uomId,
    if (description != null) 'description': description,
    if (orderedQty != null) 'ordered_qty': orderedQty,
    if (receivedQty != null) 'received_qty': receivedQty,
    if (invoicedQty != null) 'invoiced_qty': invoicedQty,
    if (pendingQty != null) 'pending_qty': pendingQty,
    if (rate != null) 'rate': rate,
    if (discountPercent != null) 'discount_percent': discountPercent,
    if (discountAmount != null) 'discount_amount': discountAmount,
    if (grossAmount != null) 'gross_amount': grossAmount,
    if (taxableAmount != null) 'taxable_amount': taxableAmount,
    if (taxCodeId != null) 'tax_code_id': taxCodeId,
    if (taxPercent != null) 'tax_percent': taxPercent,
    if (cgstAmount != null) 'cgst_amount': cgstAmount,
    if (sgstAmount != null) 'sgst_amount': sgstAmount,
    if (igstAmount != null) 'igst_amount': igstAmount,
    if (cessAmount != null) 'cess_amount': cessAmount,
    if (lineTotal != null) 'line_total': lineTotal,
    if (lineStatus != null) 'line_status': lineStatus,
    if (remarks != null) 'remarks': remarks,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
