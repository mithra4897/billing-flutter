import '../../screen.dart';

class ProductionOrderOutputModel extends JsonModel {
  const ProductionOrderOutputModel({
    super.id,
    this.productionOrderId,
    this.lineNo,
    this.itemId,
    this.uomId,
    this.outputType,
    this.plannedQty,
    this.producedQty,
    this.rejectedQty,
    this.acceptedQty,
    this.warehouseId,
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
  final int? lineNo;
  final int? itemId;
  final int? uomId;
  final String? outputType;
  final double? plannedQty;
  final double? producedQty;
  final double? rejectedQty;
  final double? acceptedQty;
  final int? warehouseId;
  final double? standardRate;
  final double? standardAmount;
  final double? actualRate;
  final double? actualAmount;
  final String? lineStatus;
  final String? remarks;
  final String? createdAt;
  final String? updatedAt;

  factory ProductionOrderOutputModel.fromJson(Map<String, dynamic> json) {
    return ProductionOrderOutputModel(
      id: JsonModel.nullableInt(json['id']),
      productionOrderId: JsonModel.nullableInt(json['production_order_id']),
      lineNo: JsonModel.nullableInt(json['line_no']),
      itemId: JsonModel.nullableInt(json['item_id']),
      uomId: JsonModel.nullableInt(json['uom_id']),
      outputType: json['output_type']?.toString(),
      plannedQty: JsonModel.nullableDouble(json['planned_qty']),
      producedQty: JsonModel.nullableDouble(json['produced_qty']),
      rejectedQty: JsonModel.nullableDouble(json['rejected_qty']),
      acceptedQty: JsonModel.nullableDouble(json['accepted_qty']),
      warehouseId: JsonModel.nullableInt(json['warehouse_id']),
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
  String toString() => 'Production Order Output';


  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (productionOrderId != null) 'production_order_id': productionOrderId,
    if (lineNo != null) 'line_no': lineNo,
    if (itemId != null) 'item_id': itemId,
    if (uomId != null) 'uom_id': uomId,
    if (outputType != null) 'output_type': outputType,
    if (plannedQty != null) 'planned_qty': plannedQty,
    if (producedQty != null) 'produced_qty': producedQty,
    if (rejectedQty != null) 'rejected_qty': rejectedQty,
    if (acceptedQty != null) 'accepted_qty': acceptedQty,
    if (warehouseId != null) 'warehouse_id': warehouseId,
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
