import '../../screen.dart';

class OpeningStockItemModel extends JsonModel {
  const OpeningStockItemModel({
    super.id,
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
      id: JsonModel.nullableInt(json['id']),
      stockOpeningId: JsonModel.nullableInt(json['stock_opening_id']),
      lineNo: JsonModel.nullableInt(json['line_no']),
      itemId: JsonModel.nullableInt(json['item_id']),
      warehouseId: JsonModel.nullableInt(json['warehouse_id']),
      batchId: JsonModel.nullableInt(json['batch_id']),
      serialId: JsonModel.nullableInt(json['serial_id']),
      uomId: JsonModel.nullableInt(json['uom_id']),
      qty: JsonModel.nullableDouble(json['qty']),
      unitCost: JsonModel.nullableDouble(json['unit_cost']),
      totalCost: JsonModel.nullableDouble(json['total_cost']),
      remarks: json['remarks']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
  @override
  String toString() => 'Opening Stock Item';


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
