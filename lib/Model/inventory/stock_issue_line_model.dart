import '../../screen.dart';

class StockIssueLineModel extends JsonModel {
  const StockIssueLineModel({
    super.id,
    this.stockIssueId,
    this.lineNo,
    this.itemId,
    this.uomId,
    this.batchId,
    this.serialId,
    this.issueQty,
    this.unitCost,
    this.totalCost,
    this.remarks,
    this.createdAt,
    this.updatedAt,
  });
  final int? stockIssueId;
  final int? lineNo;
  final int? itemId;
  final int? uomId;
  final int? batchId;
  final int? serialId;
  final double? issueQty;
  final double? unitCost;
  final double? totalCost;
  final String? remarks;
  final String? createdAt;
  final String? updatedAt;

  factory StockIssueLineModel.fromJson(Map<String, dynamic> json) {
    return StockIssueLineModel(
      id: JsonModel.nullableInt(json['id']),
      stockIssueId: JsonModel.nullableInt(json['stock_issue_id']),
      lineNo: JsonModel.nullableInt(json['line_no']),
      itemId: JsonModel.nullableInt(json['item_id']),
      uomId: JsonModel.nullableInt(json['uom_id']),
      batchId: JsonModel.nullableInt(json['batch_id']),
      serialId: JsonModel.nullableInt(json['serial_id']),
      issueQty: JsonModel.nullableDouble(json['issue_qty']),
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
  ], defaultValue: 'Stock Issue Line');


  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (stockIssueId != null) 'stock_issue_id': stockIssueId,
    if (lineNo != null) 'line_no': lineNo,
    if (itemId != null) 'item_id': itemId,
    if (uomId != null) 'uom_id': uomId,
    if (batchId != null) 'batch_id': batchId,
    if (serialId != null) 'serial_id': serialId,
    if (issueQty != null) 'issue_qty': issueQty,
    if (unitCost != null) 'unit_cost': unitCost,
    if (totalCost != null) 'total_cost': totalCost,
    if (remarks != null) 'remarks': remarks,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
