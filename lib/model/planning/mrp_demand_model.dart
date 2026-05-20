import '../../screen.dart';

class MrpDemandModel extends JsonModel {
  const MrpDemandModel({
    super.id,
    this.mrpRunId,
    this.demandSource,
    this.sourceDocumentType,
    this.sourceDocumentId,
    this.sourceLineId,
    this.itemId,
    this.warehouseId,
    this.demandDate,
    this.requiredDate,
    this.demandQty,
    this.fulfilledQty,
    this.pendingQty,
    this.priorityLevel,
    this.remarks,
    this.createdAt,
    this.updatedAt,
  });
  final int? mrpRunId;
  final String? demandSource;
  final String? sourceDocumentType;
  final int? sourceDocumentId;
  final int? sourceLineId;
  final int? itemId;
  final int? warehouseId;
  final String? demandDate;
  final String? requiredDate;
  final double? demandQty;
  final double? fulfilledQty;
  final double? pendingQty;
  final int? priorityLevel;
  final String? remarks;
  final String? createdAt;
  final String? updatedAt;

  factory MrpDemandModel.fromJson(Map<String, dynamic> json) {
    return MrpDemandModel(
      id: JsonModel.nullableInt(json['id']),
      mrpRunId: JsonModel.nullableInt(json['mrp_run_id']),
      demandSource: json['demand_source']?.toString(),
      sourceDocumentType: json['source_document_type']?.toString(),
      sourceDocumentId: JsonModel.nullableInt(json['source_document_id']),
      sourceLineId: JsonModel.nullableInt(json['source_line_id']),
      itemId: JsonModel.nullableInt(json['item_id']),
      warehouseId: JsonModel.nullableInt(json['warehouse_id']),
      demandDate: json['demand_date']?.toString(),
      requiredDate: json['required_date']?.toString(),
      demandQty: JsonModel.nullableDouble(json['demand_qty']),
      fulfilledQty: JsonModel.nullableDouble(json['fulfilled_qty']),
      pendingQty: JsonModel.nullableDouble(json['pending_qty']),
      priorityLevel: JsonModel.nullableInt(json['priority_level']),
      remarks: json['remarks']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
  @override
  String toString() => JsonModel.combineValues([
    demandDate,
    requiredDate,
    sourceDocumentType,
  ], defaultValue: 'MRP Demand');


  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (mrpRunId != null) 'mrp_run_id': mrpRunId,
    if (demandSource != null) 'demand_source': demandSource,
    if (sourceDocumentType != null) 'source_document_type': sourceDocumentType,
    if (sourceDocumentId != null) 'source_document_id': sourceDocumentId,
    if (sourceLineId != null) 'source_line_id': sourceLineId,
    if (itemId != null) 'item_id': itemId,
    if (warehouseId != null) 'warehouse_id': warehouseId,
    if (demandDate != null) 'demand_date': demandDate,
    if (requiredDate != null) 'required_date': requiredDate,
    if (demandQty != null) 'demand_qty': demandQty,
    if (fulfilledQty != null) 'fulfilled_qty': fulfilledQty,
    if (pendingQty != null) 'pending_qty': pendingQty,
    if (priorityLevel != null) 'priority_level': priorityLevel,
    if (remarks != null) 'remarks': remarks,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
