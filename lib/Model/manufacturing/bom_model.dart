import '../../screen.dart';

class BomModel extends JsonModel {
  const BomModel({
    super.id,
    this.companyId,
    this.branchId,
    this.locationId,
    this.bomCode,
    this.bomName,
    this.outputItemId,
    this.outputUomId,
    this.versionNo,
    this.revisionNo,
    this.batchSize,
    this.standardOutputQty,
    this.scrapPercent,
    this.yieldPercent,
    this.bomType,
    this.approvalStatus,
    this.effectiveFrom,
    this.effectiveTo,
    this.notes,
    this.approvedBy,
    this.approvedAt,
    this.isDefault,
    this.isActive,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  });
  final int? companyId;
  final int? branchId;
  final int? locationId;
  final String? bomCode;
  final String? bomName;
  final int? outputItemId;
  final int? outputUomId;
  final String? versionNo;
  final String? revisionNo;
  final double? batchSize;
  final double? standardOutputQty;
  final double? scrapPercent;
  final double? yieldPercent;
  final String? bomType;
  final String? approvalStatus;
  final String? effectiveFrom;
  final String? effectiveTo;
  final String? notes;
  final int? approvedBy;
  final String? approvedAt;
  final bool? isDefault;
  final bool? isActive;
  final int? createdBy;
  final int? updatedBy;
  final String? createdAt;
  final String? updatedAt;

  factory BomModel.fromJson(Map<String, dynamic> json) {
    return BomModel(
      id: ModelValue.nullableInt(json['id']),
      companyId: ModelValue.nullableInt(json['company_id']),
      branchId: ModelValue.nullableInt(json['branch_id']),
      locationId: ModelValue.nullableInt(json['location_id']),
      bomCode: json['bom_code']?.toString(),
      bomName: json['bom_name']?.toString(),
      outputItemId: ModelValue.nullableInt(json['output_item_id']),
      outputUomId: ModelValue.nullableInt(json['output_uom_id']),
      versionNo: json['version_no']?.toString(),
      revisionNo: json['revision_no']?.toString(),
      batchSize: ModelValue.nullableDouble(json['batch_size']),
      standardOutputQty: ModelValue.nullableDouble(json['standard_output_qty']),
      scrapPercent: ModelValue.nullableDouble(json['scrap_percent']),
      yieldPercent: ModelValue.nullableDouble(json['yield_percent']),
      bomType: json['bom_type']?.toString(),
      approvalStatus: json['approval_status']?.toString(),
      effectiveFrom: json['effective_from']?.toString(),
      effectiveTo: json['effective_to']?.toString(),
      notes: json['notes']?.toString(),
      approvedBy: ModelValue.nullableInt(json['approved_by']),
      approvedAt: json['approved_at']?.toString(),
      isDefault: json['is_default'] == null
          ? null
          : ModelValue.boolOf(json['is_default']),
      isActive: json['is_active'] == null
          ? null
          : ModelValue.boolOf(json['is_active']),
      createdBy: ModelValue.nullableInt(json['created_by']),
      updatedBy: ModelValue.nullableInt(json['updated_by']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
  @override
  String toString() => 'Bom';


  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (companyId != null) 'company_id': companyId,
    if (branchId != null) 'branch_id': branchId,
    if (locationId != null) 'location_id': locationId,
    if (bomCode != null) 'bom_code': bomCode,
    if (bomName != null) 'bom_name': bomName,
    if (outputItemId != null) 'output_item_id': outputItemId,
    if (outputUomId != null) 'output_uom_id': outputUomId,
    if (versionNo != null) 'version_no': versionNo,
    if (revisionNo != null) 'revision_no': revisionNo,
    if (batchSize != null) 'batch_size': batchSize,
    if (standardOutputQty != null) 'standard_output_qty': standardOutputQty,
    if (scrapPercent != null) 'scrap_percent': scrapPercent,
    if (yieldPercent != null) 'yield_percent': yieldPercent,
    if (bomType != null) 'bom_type': bomType,
    if (approvalStatus != null) 'approval_status': approvalStatus,
    if (effectiveFrom != null) 'effective_from': effectiveFrom,
    if (effectiveTo != null) 'effective_to': effectiveTo,
    if (notes != null) 'notes': notes,
    if (approvedBy != null) 'approved_by': approvedBy,
    if (approvedAt != null) 'approved_at': approvedAt,
    if (isDefault != null) 'is_default': isDefault,
    if (isActive != null) 'is_active': isActive,
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
