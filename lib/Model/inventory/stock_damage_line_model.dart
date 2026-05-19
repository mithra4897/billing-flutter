import '../../screen.dart';

class StockDamageLineModel extends JsonModel {
  const StockDamageLineModel({
    super.id,
    this.stockDamageEntryId,
    this.lineNo,
    this.itemId,
    this.uomId,
    this.batchId,
    this.serialId,
    this.damageQty,
    this.unitCost,
    this.totalCost,
    this.reason,
    this.remarks,
    this.createdAt,
    this.updatedAt,
  });
  final int? stockDamageEntryId;
  final int? lineNo;
  final int? itemId;
  final int? uomId;
  final int? batchId;
  final int? serialId;
  final double? damageQty;
  final double? unitCost;
  final double? totalCost;
  final String? reason;
  final String? remarks;
  final String? createdAt;
  final String? updatedAt;

  factory StockDamageLineModel.fromJson(Map<String, dynamic> json) {
    return StockDamageLineModel(
      id: JsonModel.nullableInt(json['id']),
      stockDamageEntryId: JsonModel.nullableInt(json['stock_damage_entry_id']),
      lineNo: JsonModel.nullableInt(json['line_no']),
      itemId: JsonModel.nullableInt(json['item_id']),
      uomId: JsonModel.nullableInt(json['uom_id']),
      batchId: JsonModel.nullableInt(json['batch_id']),
      serialId: JsonModel.nullableInt(json['serial_id']),
      damageQty: JsonModel.nullableDouble(json['damage_qty']),
      unitCost: JsonModel.nullableDouble(json['unit_cost']),
      totalCost: JsonModel.nullableDouble(json['total_cost']),
      reason: json['reason']?.toString(),
      remarks: json['remarks']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
  @override
  String toString() => 'Stock Damage Line';


  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (stockDamageEntryId != null) 'stock_damage_entry_id': stockDamageEntryId,
    if (lineNo != null) 'line_no': lineNo,
    if (itemId != null) 'item_id': itemId,
    if (uomId != null) 'uom_id': uomId,
    if (batchId != null) 'batch_id': batchId,
    if (serialId != null) 'serial_id': serialId,
    if (damageQty != null) 'damage_qty': damageQty,
    if (unitCost != null) 'unit_cost': unitCost,
    if (totalCost != null) 'total_cost': totalCost,
    if (reason != null) 'reason': reason,
    if (remarks != null) 'remarks': remarks,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
