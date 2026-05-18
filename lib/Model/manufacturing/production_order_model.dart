import '../../screen.dart';

class ProductionOrderModel implements JsonModel {
  const ProductionOrderModel({
    this.id,
    this.companyId,
    this.branchId,
    this.locationId,
    this.financialYearId,
    this.documentSeriesId,
    this.productionNo,
    this.productionDate,
    this.bomId,
    this.outputItemId,
    this.outputUomId,
    this.plannedQty,
    this.startedQty,
    this.completedQty,
    this.rejectedQty,
    this.balanceQty,
    this.sourceType,
    this.sourceDocumentType,
    this.sourceDocumentId,
    this.productionStatus,
    this.plannedStartDate,
    this.plannedEndDate,
    this.actualStartDate,
    this.actualEndDate,
    this.warehouseId,
    this.wipWarehouseId,
    this.notes,
    this.approvedBy,
    this.approvedAt,
    this.createdBy,
    this.updatedBy,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final int? companyId;
  final int? branchId;
  final int? locationId;
  final int? financialYearId;
  final int? documentSeriesId;
  final String? productionNo;
  final String? productionDate;
  final int? bomId;
  final int? outputItemId;
  final int? outputUomId;
  final double? plannedQty;
  final double? startedQty;
  final double? completedQty;
  final double? rejectedQty;
  final double? balanceQty;
  final String? sourceType;
  final String? sourceDocumentType;
  final int? sourceDocumentId;
  final String? productionStatus;
  final String? plannedStartDate;
  final String? plannedEndDate;
  final String? actualStartDate;
  final String? actualEndDate;
  final int? warehouseId;
  final int? wipWarehouseId;
  final String? notes;
  final int? approvedBy;
  final String? approvedAt;
  final int? createdBy;
  final int? updatedBy;
  final bool? isActive;
  final String? createdAt;
  final String? updatedAt;

  factory ProductionOrderModel.fromJson(Map<String, dynamic> json) {
    return ProductionOrderModel(
      id: ModelValue.nullableInt(json['id']),
      companyId: ModelValue.nullableInt(json['company_id']),
      branchId: ModelValue.nullableInt(json['branch_id']),
      locationId: ModelValue.nullableInt(json['location_id']),
      financialYearId: ModelValue.nullableInt(json['financial_year_id']),
      documentSeriesId: ModelValue.nullableInt(json['document_series_id']),
      productionNo: json['production_no']?.toString(),
      productionDate: json['production_date']?.toString(),
      bomId: ModelValue.nullableInt(json['bom_id']),
      outputItemId: ModelValue.nullableInt(json['output_item_id']),
      outputUomId: ModelValue.nullableInt(json['output_uom_id']),
      plannedQty: ModelValue.nullableDouble(json['planned_qty']),
      startedQty: ModelValue.nullableDouble(json['started_qty']),
      completedQty: ModelValue.nullableDouble(json['completed_qty']),
      rejectedQty: ModelValue.nullableDouble(json['rejected_qty']),
      balanceQty: ModelValue.nullableDouble(json['balance_qty']),
      sourceType: json['source_type']?.toString(),
      sourceDocumentType: json['source_document_type']?.toString(),
      sourceDocumentId: ModelValue.nullableInt(json['source_document_id']),
      productionStatus: json['production_status']?.toString(),
      plannedStartDate: json['planned_start_date']?.toString(),
      plannedEndDate: json['planned_end_date']?.toString(),
      actualStartDate: json['actual_start_date']?.toString(),
      actualEndDate: json['actual_end_date']?.toString(),
      warehouseId: ModelValue.nullableInt(json['warehouse_id']),
      wipWarehouseId: ModelValue.nullableInt(json['wip_warehouse_id']),
      notes: json['notes']?.toString(),
      approvedBy: ModelValue.nullableInt(json['approved_by']),
      approvedAt: json['approved_at']?.toString(),
      createdBy: ModelValue.nullableInt(json['created_by']),
      updatedBy: ModelValue.nullableInt(json['updated_by']),
      isActive: json['is_active'] == null
          ? null
          : ModelValue.boolOf(json['is_active']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (companyId != null) 'company_id': companyId,
    if (branchId != null) 'branch_id': branchId,
    if (locationId != null) 'location_id': locationId,
    if (financialYearId != null) 'financial_year_id': financialYearId,
    if (documentSeriesId != null) 'document_series_id': documentSeriesId,
    if (productionNo != null) 'production_no': productionNo,
    if (productionDate != null) 'production_date': productionDate,
    if (bomId != null) 'bom_id': bomId,
    if (outputItemId != null) 'output_item_id': outputItemId,
    if (outputUomId != null) 'output_uom_id': outputUomId,
    if (plannedQty != null) 'planned_qty': plannedQty,
    if (startedQty != null) 'started_qty': startedQty,
    if (completedQty != null) 'completed_qty': completedQty,
    if (rejectedQty != null) 'rejected_qty': rejectedQty,
    if (balanceQty != null) 'balance_qty': balanceQty,
    if (sourceType != null) 'source_type': sourceType,
    if (sourceDocumentType != null) 'source_document_type': sourceDocumentType,
    if (sourceDocumentId != null) 'source_document_id': sourceDocumentId,
    if (productionStatus != null) 'production_status': productionStatus,
    if (plannedStartDate != null) 'planned_start_date': plannedStartDate,
    if (plannedEndDate != null) 'planned_end_date': plannedEndDate,
    if (actualStartDate != null) 'actual_start_date': actualStartDate,
    if (actualEndDate != null) 'actual_end_date': actualEndDate,
    if (warehouseId != null) 'warehouse_id': warehouseId,
    if (wipWarehouseId != null) 'wip_warehouse_id': wipWarehouseId,
    if (notes != null) 'notes': notes,
    if (approvedBy != null) 'approved_by': approvedBy,
    if (approvedAt != null) 'approved_at': approvedAt,
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (isActive != null) 'is_active': isActive,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
