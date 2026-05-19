import '../../screen.dart';

class InternalStockReceiptLineModel extends JsonModel {
  const InternalStockReceiptLineModel({
    super.id,
    this.stockReceiptInternalId,
    this.lineNo,
    this.itemId,
    this.uomId,
    this.batchId,
    this.serialId,
    this.receiptQty,
    this.unitCost,
    this.totalCost,
    this.remarks,
    this.createdAt,
    this.updatedAt,
  });
  final int? stockReceiptInternalId;
  final int? lineNo;
  final int? itemId;
  final int? uomId;
  final int? batchId;
  final int? serialId;
  final double? receiptQty;
  final double? unitCost;
  final double? totalCost;
  final String? remarks;
  final String? createdAt;
  final String? updatedAt;

  factory InternalStockReceiptLineModel.fromJson(Map<String, dynamic> json) {
    return InternalStockReceiptLineModel(
      id: ModelValue.nullableInt(json['id']),
      stockReceiptInternalId: ModelValue.nullableInt(
        json['stock_receipt_internal_id'],
      ),
      lineNo: ModelValue.nullableInt(json['line_no']),
      itemId: ModelValue.nullableInt(json['item_id']),
      uomId: ModelValue.nullableInt(json['uom_id']),
      batchId: ModelValue.nullableInt(json['batch_id']),
      serialId: ModelValue.nullableInt(json['serial_id']),
      receiptQty: ModelValue.nullableDouble(json['receipt_qty']),
      unitCost: ModelValue.nullableDouble(json['unit_cost']),
      totalCost: ModelValue.nullableDouble(json['total_cost']),
      remarks: json['remarks']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
  @override
  String toString() => 'Internal Stock Receipt Line';


  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (stockReceiptInternalId != null)
      'stock_receipt_internal_id': stockReceiptInternalId,
    if (lineNo != null) 'line_no': lineNo,
    if (itemId != null) 'item_id': itemId,
    if (uomId != null) 'uom_id': uomId,
    if (batchId != null) 'batch_id': batchId,
    if (serialId != null) 'serial_id': serialId,
    if (receiptQty != null) 'receipt_qty': receiptQty,
    if (unitCost != null) 'unit_cost': unitCost,
    if (totalCost != null) 'total_cost': totalCost,
    if (remarks != null) 'remarks': remarks,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
