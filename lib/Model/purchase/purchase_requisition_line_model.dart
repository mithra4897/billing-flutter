import '../../screen.dart';

class PurchaseRequisitionLineModel extends JsonModel {
  const PurchaseRequisitionLineModel({
    super.id,
    this.purchaseRequisitionId,
    this.lineNo,
    this.itemId,
    this.warehouseId,
    this.uomId,
    this.description,
    this.requestedQty,
    this.orderedQty,
    this.pendingQty,
    this.estimatedRate,
    this.estimatedAmount,
    this.lineStatus,
    this.remarks,
    this.createdAt,
    this.updatedAt,
  });
  final int? purchaseRequisitionId;
  final int? lineNo;
  final int? itemId;
  final int? warehouseId;
  final int? uomId;
  final String? description;
  final double? requestedQty;
  final double? orderedQty;
  final double? pendingQty;
  final double? estimatedRate;
  final double? estimatedAmount;
  final String? lineStatus;
  final String? remarks;
  final String? createdAt;
  final String? updatedAt;

  factory PurchaseRequisitionLineModel.fromJson(Map<String, dynamic> json) {
    return PurchaseRequisitionLineModel(
      id: JsonModel.nullableInt(json['id']),
      purchaseRequisitionId: JsonModel.nullableInt(
        json['purchase_requisition_id'],
      ),
      lineNo: JsonModel.nullableInt(json['line_no']),
      itemId: JsonModel.nullableInt(json['item_id']),
      warehouseId: JsonModel.nullableInt(json['warehouse_id']),
      uomId: JsonModel.nullableInt(json['uom_id']),
      description: json['description']?.toString(),
      requestedQty: JsonModel.nullableDouble(json['requested_qty']),
      orderedQty: JsonModel.nullableDouble(json['ordered_qty']),
      pendingQty: JsonModel.nullableDouble(json['pending_qty']),
      estimatedRate: JsonModel.nullableDouble(json['estimated_rate']),
      estimatedAmount: JsonModel.nullableDouble(json['estimated_amount']),
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
  ], defaultValue: 'Purchase Requisition Line');


  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (purchaseRequisitionId != null)
      'purchase_requisition_id': purchaseRequisitionId,
    if (lineNo != null) 'line_no': lineNo,
    if (itemId != null) 'item_id': itemId,
    if (warehouseId != null) 'warehouse_id': warehouseId,
    if (uomId != null) 'uom_id': uomId,
    if (description != null) 'description': description,
    if (requestedQty != null) 'requested_qty': requestedQty,
    if (orderedQty != null) 'ordered_qty': orderedQty,
    if (pendingQty != null) 'pending_qty': pendingQty,
    if (estimatedRate != null) 'estimated_rate': estimatedRate,
    if (estimatedAmount != null) 'estimated_amount': estimatedAmount,
    if (lineStatus != null) 'line_status': lineStatus,
    if (remarks != null) 'remarks': remarks,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
