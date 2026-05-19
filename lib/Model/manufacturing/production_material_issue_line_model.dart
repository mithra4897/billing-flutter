import '../../screen.dart';

class ProductionMaterialIssueLineModel extends JsonModel {
  const ProductionMaterialIssueLineModel({
    super.id,
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
      id: JsonModel.nullableInt(json['id']),
      productionMaterialIssueId: JsonModel.nullableInt(
        json['production_material_issue_id'],
      ),
      productionOrderMaterialId: JsonModel.nullableInt(
        json['production_order_material_id'],
      ),
      lineNo: JsonModel.nullableInt(json['line_no']),
      itemId: JsonModel.nullableInt(json['item_id']),
      uomId: JsonModel.nullableInt(json['uom_id']),
      warehouseId: JsonModel.nullableInt(json['warehouse_id']),
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
  String toString() => 'Production Material Issue Line';


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
