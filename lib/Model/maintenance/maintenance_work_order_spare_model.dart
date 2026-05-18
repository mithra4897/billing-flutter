import '../../screen.dart';

class MaintenanceWorkOrderSpareModel implements JsonModel {
  const MaintenanceWorkOrderSpareModel({
    this.id,
    this.maintenanceWorkOrderId,
    this.lineNo,
    this.itemId,
    this.uomId,
    this.warehouseId,
    this.batchId,
    this.serialId,
    this.requiredQty,
    this.issuedQty,
    this.consumedQty,
    this.returnedQty,
    this.unitCost,
    this.totalCost,
    this.issueDocumentType,
    this.issueDocumentId,
    this.remarks,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final int? maintenanceWorkOrderId;
  final int? lineNo;
  final int? itemId;
  final int? uomId;
  final int? warehouseId;
  final int? batchId;
  final int? serialId;
  final double? requiredQty;
  final double? issuedQty;
  final double? consumedQty;
  final double? returnedQty;
  final double? unitCost;
  final double? totalCost;
  final String? issueDocumentType;
  final int? issueDocumentId;
  final String? remarks;
  final String? createdAt;
  final String? updatedAt;

  factory MaintenanceWorkOrderSpareModel.fromJson(Map<String, dynamic> json) {
    return MaintenanceWorkOrderSpareModel(
      id: ModelValue.nullableInt(json['id']),
      maintenanceWorkOrderId: ModelValue.nullableInt(
        json['maintenance_work_order_id'],
      ),
      lineNo: ModelValue.nullableInt(json['line_no']),
      itemId: ModelValue.nullableInt(json['item_id']),
      uomId: ModelValue.nullableInt(json['uom_id']),
      warehouseId: ModelValue.nullableInt(json['warehouse_id']),
      batchId: ModelValue.nullableInt(json['batch_id']),
      serialId: ModelValue.nullableInt(json['serial_id']),
      requiredQty: ModelValue.nullableDouble(json['required_qty']),
      issuedQty: ModelValue.nullableDouble(json['issued_qty']),
      consumedQty: ModelValue.nullableDouble(json['consumed_qty']),
      returnedQty: ModelValue.nullableDouble(json['returned_qty']),
      unitCost: ModelValue.nullableDouble(json['unit_cost']),
      totalCost: ModelValue.nullableDouble(json['total_cost']),
      issueDocumentType: json['issue_document_type']?.toString(),
      issueDocumentId: ModelValue.nullableInt(json['issue_document_id']),
      remarks: json['remarks']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (maintenanceWorkOrderId != null)
      'maintenance_work_order_id': maintenanceWorkOrderId,
    if (lineNo != null) 'line_no': lineNo,
    if (itemId != null) 'item_id': itemId,
    if (uomId != null) 'uom_id': uomId,
    if (warehouseId != null) 'warehouse_id': warehouseId,
    if (batchId != null) 'batch_id': batchId,
    if (serialId != null) 'serial_id': serialId,
    if (requiredQty != null) 'required_qty': requiredQty,
    if (issuedQty != null) 'issued_qty': issuedQty,
    if (consumedQty != null) 'consumed_qty': consumedQty,
    if (returnedQty != null) 'returned_qty': returnedQty,
    if (unitCost != null) 'unit_cost': unitCost,
    if (totalCost != null) 'total_cost': totalCost,
    if (issueDocumentType != null) 'issue_document_type': issueDocumentType,
    if (issueDocumentId != null) 'issue_document_id': issueDocumentId,
    if (remarks != null) 'remarks': remarks,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
