import '../../screen.dart';

class OpeningStockItemModel implements JsonModel {
  const OpeningStockItemModel({
    this.id,
    this.stockOpeningId,
    this.lineNo,
    this.itemId,
    this.warehouseId,
    this.batchId,
    this.serialId,
    this.uomId,
    this.qty,
    this.unitCost,
    this.totalCost,
    this.remarks,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final int? stockOpeningId;
  final int? lineNo;
  final int? itemId;
  final int? warehouseId;
  final int? batchId;
  final int? serialId;
  final int? uomId;
  final double? qty;
  final double? unitCost;
  final double? totalCost;
  final String? remarks;
  final String? createdAt;
  final String? updatedAt;

  factory OpeningStockItemModel.fromJson(Map<String, dynamic> json) {
    return OpeningStockItemModel(
      id: ModelValue.nullableInt(json['id']),
      stockOpeningId: ModelValue.nullableInt(json['stock_opening_id']),
      lineNo: ModelValue.nullableInt(json['line_no']),
      itemId: ModelValue.nullableInt(json['item_id']),
      warehouseId: ModelValue.nullableInt(json['warehouse_id']),
      batchId: ModelValue.nullableInt(json['batch_id']),
      serialId: ModelValue.nullableInt(json['serial_id']),
      uomId: ModelValue.nullableInt(json['uom_id']),
      qty: ModelValue.nullableDouble(json['qty']),
      unitCost: ModelValue.nullableDouble(json['unit_cost']),
      totalCost: ModelValue.nullableDouble(json['total_cost']),
      remarks: json['remarks']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (stockOpeningId != null) 'stock_opening_id': stockOpeningId,
    if (lineNo != null) 'line_no': lineNo,
    if (itemId != null) 'item_id': itemId,
    if (warehouseId != null) 'warehouse_id': warehouseId,
    if (batchId != null) 'batch_id': batchId,
    if (serialId != null) 'serial_id': serialId,
    if (uomId != null) 'uom_id': uomId,
    if (qty != null) 'qty': qty,
    if (unitCost != null) 'unit_cost': unitCost,
    if (totalCost != null) 'total_cost': totalCost,
    if (remarks != null) 'remarks': remarks,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
