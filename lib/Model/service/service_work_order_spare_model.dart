import '../../screen.dart';

class ServiceWorkOrderSpareModel implements JsonModel {
  const ServiceWorkOrderSpareModel({
    this.id,
    this.serviceWorkOrderId,
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
    this.warrantyCovered,
    this.chargeableToCustomer,
    this.unitCost,
    this.totalCost,
    this.billableRate,
    this.billableAmount,
    this.issueDocumentType,
    this.issueDocumentId,
    this.remarks,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final int? serviceWorkOrderId;
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
  final bool? warrantyCovered;
  final bool? chargeableToCustomer;
  final double? unitCost;
  final double? totalCost;
  final double? billableRate;
  final double? billableAmount;
  final String? issueDocumentType;
  final int? issueDocumentId;
  final String? remarks;
  final String? createdAt;
  final String? updatedAt;

  factory ServiceWorkOrderSpareModel.fromJson(Map<String, dynamic> json) {
    return ServiceWorkOrderSpareModel(
      id: ModelValue.nullableInt(json['id']),
      serviceWorkOrderId: ModelValue.nullableInt(json['service_work_order_id']),
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
      warrantyCovered: json['warranty_covered'] == null
          ? null
          : ModelValue.boolOf(json['warranty_covered']),
      chargeableToCustomer: json['chargeable_to_customer'] == null
          ? null
          : ModelValue.boolOf(json['chargeable_to_customer']),
      unitCost: ModelValue.nullableDouble(json['unit_cost']),
      totalCost: ModelValue.nullableDouble(json['total_cost']),
      billableRate: ModelValue.nullableDouble(json['billable_rate']),
      billableAmount: ModelValue.nullableDouble(json['billable_amount']),
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
    if (serviceWorkOrderId != null) 'service_work_order_id': serviceWorkOrderId,
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
    if (warrantyCovered != null) 'warranty_covered': warrantyCovered,
    if (chargeableToCustomer != null)
      'chargeable_to_customer': chargeableToCustomer,
    if (unitCost != null) 'unit_cost': unitCost,
    if (totalCost != null) 'total_cost': totalCost,
    if (billableRate != null) 'billable_rate': billableRate,
    if (billableAmount != null) 'billable_amount': billableAmount,
    if (issueDocumentType != null) 'issue_document_type': issueDocumentType,
    if (issueDocumentId != null) 'issue_document_id': issueDocumentId,
    if (remarks != null) 'remarks': remarks,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
