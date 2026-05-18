import '../../screen.dart';

class MrpDemandModel implements JsonModel {
  const MrpDemandModel({
    this.id,
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

  final int? id;
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
      id: ModelValue.nullableInt(json['id']),
      mrpRunId: ModelValue.nullableInt(json['mrp_run_id']),
      demandSource: json['demand_source']?.toString(),
      sourceDocumentType: json['source_document_type']?.toString(),
      sourceDocumentId: ModelValue.nullableInt(json['source_document_id']),
      sourceLineId: ModelValue.nullableInt(json['source_line_id']),
      itemId: ModelValue.nullableInt(json['item_id']),
      warehouseId: ModelValue.nullableInt(json['warehouse_id']),
      demandDate: json['demand_date']?.toString(),
      requiredDate: json['required_date']?.toString(),
      demandQty: ModelValue.nullableDouble(json['demand_qty']),
      fulfilledQty: ModelValue.nullableDouble(json['fulfilled_qty']),
      pendingQty: ModelValue.nullableDouble(json['pending_qty']),
      priorityLevel: ModelValue.nullableInt(json['priority_level']),
      remarks: json['remarks']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

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
