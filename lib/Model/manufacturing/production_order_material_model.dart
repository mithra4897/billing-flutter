import '../../screen.dart';

class ProductionOrderMaterialModel extends JsonModel {
  const ProductionOrderMaterialModel({
    super.id,
    this.productionOrderId,
    this.bomLineId,
    this.lineNo,
    this.itemId,
    this.uomId,
    this.lineType,
    this.plannedQty,
    this.issuedQty,
    this.returnedQty,
    this.consumedQty,
    this.balanceQty,
    this.warehouseId,
    this.issueMethod,
    this.standardRate,
    this.standardAmount,
    this.actualRate,
    this.actualAmount,
    this.lineStatus,
    this.remarks,
    this.createdAt,
    this.updatedAt,
  });
  final int? productionOrderId;
  final int? bomLineId;
  final int? lineNo;
  final int? itemId;
  final int? uomId;
  final String? lineType;
  final double? plannedQty;
  final double? issuedQty;
  final double? returnedQty;
  final double? consumedQty;
  final double? balanceQty;
  final int? warehouseId;
  final String? issueMethod;
  final double? standardRate;
  final double? standardAmount;
  final double? actualRate;
  final double? actualAmount;
  final String? lineStatus;
  final String? remarks;
  final String? createdAt;
  final String? updatedAt;

  factory ProductionOrderMaterialModel.fromJson(Map<String, dynamic> json) {
    return ProductionOrderMaterialModel(
      id: JsonModel.nullableInt(json['id']),
      productionOrderId: JsonModel.nullableInt(json['production_order_id']),
      bomLineId: JsonModel.nullableInt(json['bom_line_id']),
      lineNo: JsonModel.nullableInt(json['line_no']),
      itemId: JsonModel.nullableInt(json['item_id']),
      uomId: JsonModel.nullableInt(json['uom_id']),
      lineType: json['line_type']?.toString(),
      plannedQty: JsonModel.nullableDouble(json['planned_qty']),
      issuedQty: JsonModel.nullableDouble(json['issued_qty']),
      returnedQty: JsonModel.nullableDouble(json['returned_qty']),
      consumedQty: JsonModel.nullableDouble(json['consumed_qty']),
      balanceQty: JsonModel.nullableDouble(json['balance_qty']),
      warehouseId: JsonModel.nullableInt(json['warehouse_id']),
      issueMethod: json['issue_method']?.toString(),
      standardRate: JsonModel.nullableDouble(json['standard_rate']),
      standardAmount: JsonModel.nullableDouble(json['standard_amount']),
      actualRate: JsonModel.nullableDouble(json['actual_rate']),
      actualAmount: JsonModel.nullableDouble(json['actual_amount']),
      lineStatus: json['line_status']?.toString(),
      remarks: json['remarks']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
  @override
  String toString() => JsonModel.combineValues([
    lineNo,
    lineStatus,
    lineType,
  ], defaultValue: 'Production Order Material');


  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (productionOrderId != null) 'production_order_id': productionOrderId,
    if (bomLineId != null) 'bom_line_id': bomLineId,
    if (lineNo != null) 'line_no': lineNo,
    if (itemId != null) 'item_id': itemId,
    if (uomId != null) 'uom_id': uomId,
    if (lineType != null) 'line_type': lineType,
    if (plannedQty != null) 'planned_qty': plannedQty,
    if (issuedQty != null) 'issued_qty': issuedQty,
    if (returnedQty != null) 'returned_qty': returnedQty,
    if (consumedQty != null) 'consumed_qty': consumedQty,
    if (balanceQty != null) 'balance_qty': balanceQty,
    if (warehouseId != null) 'warehouse_id': warehouseId,
    if (issueMethod != null) 'issue_method': issueMethod,
    if (standardRate != null) 'standard_rate': standardRate,
    if (standardAmount != null) 'standard_amount': standardAmount,
    if (actualRate != null) 'actual_rate': actualRate,
    if (actualAmount != null) 'actual_amount': actualAmount,
    if (lineStatus != null) 'line_status': lineStatus,
    if (remarks != null) 'remarks': remarks,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
