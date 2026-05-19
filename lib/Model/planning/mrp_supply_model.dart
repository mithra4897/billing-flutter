import '../../screen.dart';

class MrpSupplyModel extends JsonModel {
  const MrpSupplyModel({
    super.id,
    this.mrpRunId,
    this.supplySource,
    this.sourceDocumentType,
    this.sourceDocumentId,
    this.sourceLineId,
    this.itemId,
    this.warehouseId,
    this.availableDate,
    this.supplyQty,
    this.allocatedQty,
    this.availableQty,
    this.remarks,
    this.createdAt,
    this.updatedAt,
  });
  final int? mrpRunId;
  final String? supplySource;
  final String? sourceDocumentType;
  final int? sourceDocumentId;
  final int? sourceLineId;
  final int? itemId;
  final int? warehouseId;
  final String? availableDate;
  final double? supplyQty;
  final double? allocatedQty;
  final double? availableQty;
  final String? remarks;
  final String? createdAt;
  final String? updatedAt;

  factory MrpSupplyModel.fromJson(Map<String, dynamic> json) {
    return MrpSupplyModel(
      id: JsonModel.nullableInt(json['id']),
      mrpRunId: JsonModel.nullableInt(json['mrp_run_id']),
      supplySource: json['supply_source']?.toString(),
      sourceDocumentType: json['source_document_type']?.toString(),
      sourceDocumentId: JsonModel.nullableInt(json['source_document_id']),
      sourceLineId: JsonModel.nullableInt(json['source_line_id']),
      itemId: JsonModel.nullableInt(json['item_id']),
      warehouseId: JsonModel.nullableInt(json['warehouse_id']),
      availableDate: json['available_date']?.toString(),
      supplyQty: JsonModel.nullableDouble(json['supply_qty']),
      allocatedQty: JsonModel.nullableDouble(json['allocated_qty']),
      availableQty: JsonModel.nullableDouble(json['available_qty']),
      remarks: json['remarks']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
  @override
  String toString() => 'Mrp Supply';


  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (mrpRunId != null) 'mrp_run_id': mrpRunId,
    if (supplySource != null) 'supply_source': supplySource,
    if (sourceDocumentType != null) 'source_document_type': sourceDocumentType,
    if (sourceDocumentId != null) 'source_document_id': sourceDocumentId,
    if (sourceLineId != null) 'source_line_id': sourceLineId,
    if (itemId != null) 'item_id': itemId,
    if (warehouseId != null) 'warehouse_id': warehouseId,
    if (availableDate != null) 'available_date': availableDate,
    if (supplyQty != null) 'supply_qty': supplyQty,
    if (allocatedQty != null) 'allocated_qty': allocatedQty,
    if (availableQty != null) 'available_qty': availableQty,
    if (remarks != null) 'remarks': remarks,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
