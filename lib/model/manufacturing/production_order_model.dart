import '../../screen.dart';

class ProductionOrderModel extends JsonModel {
  const ProductionOrderModel({
    super.id,
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
    this.bom,
    this.outputItem,
    this.outputUom,
    this.warehouse,
    this.wipWarehouse,
    this.materials = const <Map<String, dynamic>>[],
    this.operations = const <Map<String, dynamic>>[],
    this.outputs = const <Map<String, dynamic>>[],
  });
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
  final Map<String, dynamic>? bom;
  final Map<String, dynamic>? outputItem;
  final Map<String, dynamic>? outputUom;
  final Map<String, dynamic>? warehouse;
  final Map<String, dynamic>? wipWarehouse;
  final List<Map<String, dynamic>> materials;
  final List<Map<String, dynamic>> operations;
  final List<Map<String, dynamic>> outputs;

  factory ProductionOrderModel.fromJson(Map<String, dynamic> json) {
    return ProductionOrderModel(
      id: JsonModel.nullableInt(json['id']),
      companyId: JsonModel.nullableInt(json['company_id']),
      branchId: JsonModel.nullableInt(json['branch_id']),
      locationId: JsonModel.nullableInt(json['location_id']),
      financialYearId: JsonModel.nullableInt(json['financial_year_id']),
      documentSeriesId: JsonModel.nullableInt(json['document_series_id']),
      productionNo: json['production_no']?.toString(),
      productionDate: json['production_date']?.toString(),
      bomId: JsonModel.nullableInt(json['bom_id']),
      outputItemId: JsonModel.nullableInt(json['output_item_id']),
      outputUomId: JsonModel.nullableInt(json['output_uom_id']),
      plannedQty: JsonModel.nullableDouble(json['planned_qty']),
      startedQty: JsonModel.nullableDouble(json['started_qty']),
      completedQty: JsonModel.nullableDouble(json['completed_qty']),
      rejectedQty: JsonModel.nullableDouble(json['rejected_qty']),
      balanceQty: JsonModel.nullableDouble(json['balance_qty']),
      sourceType: json['source_type']?.toString(),
      sourceDocumentType: json['source_document_type']?.toString(),
      sourceDocumentId: JsonModel.nullableInt(json['source_document_id']),
      productionStatus: json['production_status']?.toString(),
      plannedStartDate: json['planned_start_date']?.toString(),
      plannedEndDate: json['planned_end_date']?.toString(),
      actualStartDate: json['actual_start_date']?.toString(),
      actualEndDate: json['actual_end_date']?.toString(),
      warehouseId: JsonModel.nullableInt(json['warehouse_id']),
      wipWarehouseId: JsonModel.nullableInt(json['wip_warehouse_id']),
      notes: json['notes']?.toString(),
      approvedBy: JsonModel.nullableInt(json['approved_by']),
      approvedAt: json['approved_at']?.toString(),
      createdBy: JsonModel.nullableInt(json['created_by']),
      updatedBy: JsonModel.nullableInt(json['updated_by']),
      isActive: json['is_active'] == null
          ? null
          : JsonModel.boolOf(json['is_active']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      bom: JsonModel.mapOf(json['bom']),
      outputItem:
          JsonModel.mapOf(json['outputItem']) ??
          JsonModel.mapOf(json['output_item']),
      outputUom:
          JsonModel.mapOf(json['outputUom']) ??
          JsonModel.mapOf(json['output_uom']),
      warehouse: JsonModel.mapOf(json['warehouse']),
      wipWarehouse:
          JsonModel.mapOf(json['wipWarehouse']) ??
          JsonModel.mapOf(json['wip_warehouse']),
      materials: JsonModel.mapListOf(json['materials']),
      operations: JsonModel.mapListOf(json['operations']),
      outputs: JsonModel.mapListOf(json['outputs']),
    );
  }
  @override
  String toString() => JsonModel.combineValues([
    productionNo,
    productionDate,
    plannedStartDate,
  ], defaultValue: 'Production Order');


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
    if (bom != null) 'bom': bom,
    if (outputItem != null) 'outputItem': outputItem,
    if (outputUom != null) 'outputUom': outputUom,
    if (warehouse != null) 'warehouse': warehouse,
    if (wipWarehouse != null) 'wipWarehouse': wipWarehouse,
    if (materials.isNotEmpty) 'materials': materials,
    if (operations.isNotEmpty) 'operations': operations,
    if (outputs.isNotEmpty) 'outputs': outputs,
  };
}
