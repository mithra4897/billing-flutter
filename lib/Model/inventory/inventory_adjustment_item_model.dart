import '../../screen.dart';

class InventoryAdjustmentItemModel extends JsonModel {
  const InventoryAdjustmentItemModel({
    super.id,
    this.stockAdjustmentId,
    this.lineNo,
    this.itemId,
    this.warehouseId,
    this.batchId,
    this.serialId,
    this.uomId,
    this.systemQty,
    this.actualQty,
    this.adjustmentQty,
    this.unitCost,
    this.totalCost,
    this.adjustmentDirection,
    this.remarks,
    this.createdAt,
    this.updatedAt,
  });
  final int? stockAdjustmentId;
  final int? lineNo;
  final int? itemId;
  final int? warehouseId;
  final int? batchId;
  final int? serialId;
  final int? uomId;
  final double? systemQty;
  final double? actualQty;
  final double? adjustmentQty;
  final double? unitCost;
  final double? totalCost;
  final String? adjustmentDirection;
  final String? remarks;
  final String? createdAt;
  final String? updatedAt;

  factory InventoryAdjustmentItemModel.fromJson(Map<String, dynamic> json) {
    return InventoryAdjustmentItemModel(
      id: JsonModel.nullableInt(json['id']),
      stockAdjustmentId: JsonModel.nullableInt(json['stock_adjustment_id']),
      lineNo: JsonModel.nullableInt(json['line_no']),
      itemId: JsonModel.nullableInt(json['item_id']),
      warehouseId: JsonModel.nullableInt(json['warehouse_id']),
      batchId: JsonModel.nullableInt(json['batch_id']),
      serialId: JsonModel.nullableInt(json['serial_id']),
      uomId: JsonModel.nullableInt(json['uom_id']),
      systemQty: JsonModel.nullableDouble(json['system_qty']),
      actualQty: JsonModel.nullableDouble(json['actual_qty']),
      adjustmentQty: JsonModel.nullableDouble(json['adjustment_qty']),
      unitCost: JsonModel.nullableDouble(json['unit_cost']),
      totalCost: JsonModel.nullableDouble(json['total_cost']),
      adjustmentDirection: json['adjustment_direction']?.toString(),
      remarks: json['remarks']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
  @override
  String toString() => JsonModel.combineValues([
    lineNo,
  ], defaultValue: 'Inventory Adjustment Item');


  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (stockAdjustmentId != null) 'stock_adjustment_id': stockAdjustmentId,
    if (lineNo != null) 'line_no': lineNo,
    if (itemId != null) 'item_id': itemId,
    if (warehouseId != null) 'warehouse_id': warehouseId,
    if (batchId != null) 'batch_id': batchId,
    if (serialId != null) 'serial_id': serialId,
    if (uomId != null) 'uom_id': uomId,
    if (systemQty != null) 'system_qty': systemQty,
    if (actualQty != null) 'actual_qty': actualQty,
    if (adjustmentQty != null) 'adjustment_qty': adjustmentQty,
    if (unitCost != null) 'unit_cost': unitCost,
    if (totalCost != null) 'total_cost': totalCost,
    if (adjustmentDirection != null)
      'adjustment_direction': adjustmentDirection,
    if (remarks != null) 'remarks': remarks,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
