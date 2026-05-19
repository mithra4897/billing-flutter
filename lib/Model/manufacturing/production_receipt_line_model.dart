import '../../screen.dart';

class ProductionReceiptLineModel extends JsonModel {
  const ProductionReceiptLineModel({
    super.id,
    this.productionReceiptId,
    this.productionOrderOutputId,
    this.lineNo,
    this.itemId,
    this.uomId,
    this.warehouseId,
    this.batchId,
    this.serialId,
    this.receiptQty,
    this.acceptedQty,
    this.rejectedQty,
    this.unitCost,
    this.totalCost,
    this.outputType,
    this.remarks,
    this.createdAt,
    this.updatedAt,
  });
  final int? productionReceiptId;
  final int? productionOrderOutputId;
  final int? lineNo;
  final int? itemId;
  final int? uomId;
  final int? warehouseId;
  final int? batchId;
  final int? serialId;
  final double? receiptQty;
  final double? acceptedQty;
  final double? rejectedQty;
  final double? unitCost;
  final double? totalCost;
  final String? outputType;
  final String? remarks;
  final String? createdAt;
  final String? updatedAt;

  factory ProductionReceiptLineModel.fromJson(Map<String, dynamic> json) {
    return ProductionReceiptLineModel(
      id: ModelValue.nullableInt(json['id']),
      productionReceiptId: ModelValue.nullableInt(
        json['production_receipt_id'],
      ),
      productionOrderOutputId: ModelValue.nullableInt(
        json['production_order_output_id'],
      ),
      lineNo: ModelValue.nullableInt(json['line_no']),
      itemId: ModelValue.nullableInt(json['item_id']),
      uomId: ModelValue.nullableInt(json['uom_id']),
      warehouseId: ModelValue.nullableInt(json['warehouse_id']),
      batchId: ModelValue.nullableInt(json['batch_id']),
      serialId: ModelValue.nullableInt(json['serial_id']),
      receiptQty: ModelValue.nullableDouble(json['receipt_qty']),
      acceptedQty: ModelValue.nullableDouble(json['accepted_qty']),
      rejectedQty: ModelValue.nullableDouble(json['rejected_qty']),
      unitCost: ModelValue.nullableDouble(json['unit_cost']),
      totalCost: ModelValue.nullableDouble(json['total_cost']),
      outputType: json['output_type']?.toString(),
      remarks: json['remarks']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
  @override
  String toString() => 'Production Receipt Line';


  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (productionReceiptId != null)
      'production_receipt_id': productionReceiptId,
    if (productionOrderOutputId != null)
      'production_order_output_id': productionOrderOutputId,
    if (lineNo != null) 'line_no': lineNo,
    if (itemId != null) 'item_id': itemId,
    if (uomId != null) 'uom_id': uomId,
    if (warehouseId != null) 'warehouse_id': warehouseId,
    if (batchId != null) 'batch_id': batchId,
    if (serialId != null) 'serial_id': serialId,
    if (receiptQty != null) 'receipt_qty': receiptQty,
    if (acceptedQty != null) 'accepted_qty': acceptedQty,
    if (rejectedQty != null) 'rejected_qty': rejectedQty,
    if (unitCost != null) 'unit_cost': unitCost,
    if (totalCost != null) 'total_cost': totalCost,
    if (outputType != null) 'output_type': outputType,
    if (remarks != null) 'remarks': remarks,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
