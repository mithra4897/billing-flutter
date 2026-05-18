import '../../screen.dart';

class MrpRecommendationModel implements JsonModel {
  const MrpRecommendationModel({
    this.id,
    this.mrpRunId,
    this.mrpNetRequirementId,
    this.recommendationType,
    this.itemId,
    this.warehouseId,
    this.recommendedQty,
    this.recommendedDate,
    this.priorityLevel,
    this.supplierPartyId,
    this.bomId,
    this.sourceWarehouseId,
    this.recommendationStatus,
    this.convertedDocumentType,
    this.convertedDocumentId,
    this.notes,
    this.approvedBy,
    this.approvedAt,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final int? mrpRunId;
  final int? mrpNetRequirementId;
  final String? recommendationType;
  final int? itemId;
  final int? warehouseId;
  final double? recommendedQty;
  final String? recommendedDate;
  final int? priorityLevel;
  final int? supplierPartyId;
  final int? bomId;
  final int? sourceWarehouseId;
  final String? recommendationStatus;
  final String? convertedDocumentType;
  final int? convertedDocumentId;
  final String? notes;
  final int? approvedBy;
  final String? approvedAt;
  final String? createdAt;
  final String? updatedAt;

  factory MrpRecommendationModel.fromJson(Map<String, dynamic> json) {
    return MrpRecommendationModel(
      id: ModelValue.nullableInt(json['id']),
      mrpRunId: ModelValue.nullableInt(json['mrp_run_id']),
      mrpNetRequirementId: ModelValue.nullableInt(
        json['mrp_net_requirement_id'],
      ),
      recommendationType: json['recommendation_type']?.toString(),
      itemId: ModelValue.nullableInt(json['item_id']),
      warehouseId: ModelValue.nullableInt(json['warehouse_id']),
      recommendedQty: ModelValue.nullableDouble(json['recommended_qty']),
      recommendedDate: json['recommended_date']?.toString(),
      priorityLevel: ModelValue.nullableInt(json['priority_level']),
      supplierPartyId: ModelValue.nullableInt(json['supplier_party_id']),
      bomId: ModelValue.nullableInt(json['bom_id']),
      sourceWarehouseId: ModelValue.nullableInt(json['source_warehouse_id']),
      recommendationStatus: json['recommendation_status']?.toString(),
      convertedDocumentType: json['converted_document_type']?.toString(),
      convertedDocumentId: ModelValue.nullableInt(
        json['converted_document_id'],
      ),
      notes: json['notes']?.toString(),
      approvedBy: ModelValue.nullableInt(json['approved_by']),
      approvedAt: json['approved_at']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (mrpRunId != null) 'mrp_run_id': mrpRunId,
    if (mrpNetRequirementId != null)
      'mrp_net_requirement_id': mrpNetRequirementId,
    if (recommendationType != null) 'recommendation_type': recommendationType,
    if (itemId != null) 'item_id': itemId,
    if (warehouseId != null) 'warehouse_id': warehouseId,
    if (recommendedQty != null) 'recommended_qty': recommendedQty,
    if (recommendedDate != null) 'recommended_date': recommendedDate,
    if (priorityLevel != null) 'priority_level': priorityLevel,
    if (supplierPartyId != null) 'supplier_party_id': supplierPartyId,
    if (bomId != null) 'bom_id': bomId,
    if (sourceWarehouseId != null) 'source_warehouse_id': sourceWarehouseId,
    if (recommendationStatus != null)
      'recommendation_status': recommendationStatus,
    if (convertedDocumentType != null)
      'converted_document_type': convertedDocumentType,
    if (convertedDocumentId != null)
      'converted_document_id': convertedDocumentId,
    if (notes != null) 'notes': notes,
    if (approvedBy != null) 'approved_by': approvedBy,
    if (approvedAt != null) 'approved_at': approvedAt,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
