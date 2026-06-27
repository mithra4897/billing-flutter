import '../../screen.dart';

class OpeningStockItemModel extends JsonModel {
  const OpeningStockItemModel({
    super.id,
    this.stockOpeningId,
    this.lineNo,
    this.itemId,
    this.itemCode,
    this.itemName,
    this.categoryCode,
    this.categoryName,
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
  final String? itemCode;
  final String? itemName;
  final String? categoryCode;
  final String? categoryName;
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
    final item = JsonModel.mapOf(json['item']) ?? const <String, dynamic>{};
    final category =
        JsonModel.mapOf(item['category']) ?? const <String, dynamic>{};
    return OpeningStockItemModel(
      id: JsonModel.nullableInt(json['id']),
      stockOpeningId: JsonModel.nullableInt(json['stock_opening_id']),
      lineNo: JsonModel.nullableInt(json['line_no']),
      itemId: JsonModel.nullableInt(json['item_id'] ?? item['id']),
      itemCode: JsonModel.nullableString(
        json['item_code'] ?? item['item_code'],
      ),
      itemName: JsonModel.nullableString(
        json['item_name'] ?? item['item_name'],
      ),
      categoryCode: JsonModel.nullableString(
        json['category_code'] ??
            item['category_code'] ??
            category['category_code'],
      ),
      categoryName: JsonModel.nullableString(
        json['category_name'] ??
            item['category_name'] ??
            category['category_name'],
      ),
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
  String toString() => JsonModel.combineValues([
    lineNo,
    itemName,
    itemCode,
  ], defaultValue: 'Opening Stock Item');

  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (stockOpeningId != null) 'stock_opening_id': stockOpeningId,
    if (lineNo != null) 'line_no': lineNo,
    if (itemId != null) 'item_id': itemId,
    if (itemCode != null) 'item_code': itemCode,
    if (itemName != null) 'item_name': itemName,
    if (categoryCode != null) 'category_code': categoryCode,
    if (categoryName != null) 'category_name': categoryName,
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
