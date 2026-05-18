import '../../screen.dart';

class ProductionMaterialIssueLineModel implements JsonModel {
  const ProductionMaterialIssueLineModel({
    this.id,
    this.productionMaterialIssueId,
    this.productionOrderMaterialId,
    this.lineNo,
    this.itemId,
    this.uomId,
    this.warehouseId,
    this.batchId,
    this.serialId,
    this.issueQty,
    this.unitCost,
    this.totalCost,
    this.remarks,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final int? productionMaterialIssueId;
  final int? productionOrderMaterialId;
  final int? lineNo;
  final int? itemId;
  final int? uomId;
  final int? warehouseId;
  final int? batchId;
  final int? serialId;
  final double? issueQty;
  final double? unitCost;
  final double? totalCost;
  final String? remarks;
  final String? createdAt;
  final String? updatedAt;

  factory ProductionMaterialIssueLineModel.fromJson(Map<String, dynamic> json) {
    return ProductionMaterialIssueLineModel(
      id: ModelValue.nullableInt(json['id']),
      productionMaterialIssueId: ModelValue.nullableInt(
        json['production_material_issue_id'],
      ),
      productionOrderMaterialId: ModelValue.nullableInt(
        json['production_order_material_id'],
      ),
      lineNo: ModelValue.nullableInt(json['line_no']),
      itemId: ModelValue.nullableInt(json['item_id']),
      uomId: ModelValue.nullableInt(json['uom_id']),
      warehouseId: ModelValue.nullableInt(json['warehouse_id']),
      batchId: ModelValue.nullableInt(json['batch_id']),
      serialId: ModelValue.nullableInt(json['serial_id']),
      issueQty: ModelValue.nullableDouble(json['issue_qty']),
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
    if (productionMaterialIssueId != null)
      'production_material_issue_id': productionMaterialIssueId,
    if (productionOrderMaterialId != null)
      'production_order_material_id': productionOrderMaterialId,
    if (lineNo != null) 'line_no': lineNo,
    if (itemId != null) 'item_id': itemId,
    if (uomId != null) 'uom_id': uomId,
    if (warehouseId != null) 'warehouse_id': warehouseId,
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
