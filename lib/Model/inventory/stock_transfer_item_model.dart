import '../../screen.dart';

class StockTransferItemModel extends JsonModel {
  const StockTransferItemModel({
    super.id,
    this.stockTransferId,
    this.lineNo,
    this.itemId,
    this.fromBatchId,
    this.toBatchId,
    this.fromSerialId,
    this.toSerialId,
    this.uomId,
    this.transferQty,
    this.unitCost,
    this.totalCost,
    this.remarks,
    this.createdAt,
    this.updatedAt,
  });
  final int? stockTransferId;
  final int? lineNo;
  final int? itemId;
  final int? fromBatchId;
  final int? toBatchId;
  final int? fromSerialId;
  final int? toSerialId;
  final int? uomId;
  final double? transferQty;
  final double? unitCost;
  final double? totalCost;
  final String? remarks;
  final String? createdAt;
  final String? updatedAt;

  factory StockTransferItemModel.fromJson(Map<String, dynamic> json) {
    return StockTransferItemModel(
      id: JsonModel.nullableInt(json['id']),
      stockTransferId: JsonModel.nullableInt(json['stock_transfer_id']),
      lineNo: JsonModel.nullableInt(json['line_no']),
      itemId: JsonModel.nullableInt(json['item_id']),
      fromBatchId: JsonModel.nullableInt(json['from_batch_id']),
      toBatchId: JsonModel.nullableInt(json['to_batch_id']),
      fromSerialId: JsonModel.nullableInt(json['from_serial_id']),
      toSerialId: JsonModel.nullableInt(json['to_serial_id']),
      uomId: JsonModel.nullableInt(json['uom_id']),
      transferQty: JsonModel.nullableDouble(json['transfer_qty']),
      unitCost: JsonModel.nullableDouble(json['unit_cost']),
      totalCost: JsonModel.nullableDouble(json['total_cost']),
      remarks: json['remarks']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
  @override
  String toString() => 'Stock Transfer Item';


  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (stockTransferId != null) 'stock_transfer_id': stockTransferId,
    if (lineNo != null) 'line_no': lineNo,
    if (itemId != null) 'item_id': itemId,
    if (fromBatchId != null) 'from_batch_id': fromBatchId,
    if (toBatchId != null) 'to_batch_id': toBatchId,
    if (fromSerialId != null) 'from_serial_id': fromSerialId,
    if (toSerialId != null) 'to_serial_id': toSerialId,
    if (uomId != null) 'uom_id': uomId,
    if (transferQty != null) 'transfer_qty': transferQty,
    if (unitCost != null) 'unit_cost': unitCost,
    if (totalCost != null) 'total_cost': totalCost,
    if (remarks != null) 'remarks': remarks,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
