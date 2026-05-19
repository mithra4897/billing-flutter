import '../../screen.dart';

class QcInspectionModel extends JsonModel {
  const QcInspectionModel({
    super.id,
    this.companyId,
    this.branchId,
    this.locationId,
    this.financialYearId,
    this.documentSeriesId,
    this.inspectionNo,
    this.inspectionDate,
    this.qcPlanId,
    this.inspectionScope,
    this.sourceDocumentType,
    this.sourceDocumentId,
    this.sourceLineId,
    this.itemId,
    this.uomId,
    this.warehouseId,
    this.batchId,
    this.serialId,
    this.lotNo,
    this.sampleSize,
    this.inspectedQty,
    this.acceptedQty,
    this.rejectedQty,
    this.holdQty,
    this.reworkQty,
    this.inspectionStatus,
    this.finalResult,
    this.inspectedBy,
    this.inspectedAt,
    this.approvedBy,
    this.approvedAt,
    this.remarks,
    this.createdBy,
    this.updatedBy,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });
  final int? companyId;
  final int? branchId;
  final int? locationId;
  final int? financialYearId;
  final int? documentSeriesId;
  final String? inspectionNo;
  final String? inspectionDate;
  final int? qcPlanId;
  final String? inspectionScope;
  final String? sourceDocumentType;
  final int? sourceDocumentId;
  final int? sourceLineId;
  final int? itemId;
  final int? uomId;
  final int? warehouseId;
  final int? batchId;
  final int? serialId;
  final String? lotNo;
  final double? sampleSize;
  final double? inspectedQty;
  final double? acceptedQty;
  final double? rejectedQty;
  final double? holdQty;
  final double? reworkQty;
  final String? inspectionStatus;
  final String? finalResult;
  final int? inspectedBy;
  final String? inspectedAt;
  final int? approvedBy;
  final String? approvedAt;
  final String? remarks;
  final int? createdBy;
  final int? updatedBy;
  final bool? isActive;
  final String? createdAt;
  final String? updatedAt;

  factory QcInspectionModel.fromJson(Map<String, dynamic> json) {
    return QcInspectionModel(
      id: JsonModel.nullableInt(json['id']),
      companyId: JsonModel.nullableInt(json['company_id']),
      branchId: JsonModel.nullableInt(json['branch_id']),
      locationId: JsonModel.nullableInt(json['location_id']),
      financialYearId: JsonModel.nullableInt(json['financial_year_id']),
      documentSeriesId: JsonModel.nullableInt(json['document_series_id']),
      inspectionNo: json['inspection_no']?.toString(),
      inspectionDate: json['inspection_date']?.toString(),
      qcPlanId: JsonModel.nullableInt(json['qc_plan_id']),
      inspectionScope: json['inspection_scope']?.toString(),
      sourceDocumentType: json['source_document_type']?.toString(),
      sourceDocumentId: JsonModel.nullableInt(json['source_document_id']),
      sourceLineId: JsonModel.nullableInt(json['source_line_id']),
      itemId: JsonModel.nullableInt(json['item_id']),
      uomId: JsonModel.nullableInt(json['uom_id']),
      warehouseId: JsonModel.nullableInt(json['warehouse_id']),
      batchId: JsonModel.nullableInt(json['batch_id']),
      serialId: JsonModel.nullableInt(json['serial_id']),
      lotNo: json['lot_no']?.toString(),
      sampleSize: JsonModel.nullableDouble(json['sample_size']),
      inspectedQty: JsonModel.nullableDouble(json['inspected_qty']),
      acceptedQty: JsonModel.nullableDouble(json['accepted_qty']),
      rejectedQty: JsonModel.nullableDouble(json['rejected_qty']),
      holdQty: JsonModel.nullableDouble(json['hold_qty']),
      reworkQty: JsonModel.nullableDouble(json['rework_qty']),
      inspectionStatus: json['inspection_status']?.toString(),
      finalResult: json['final_result']?.toString(),
      inspectedBy: JsonModel.nullableInt(json['inspected_by']),
      inspectedAt: json['inspected_at']?.toString(),
      approvedBy: JsonModel.nullableInt(json['approved_by']),
      approvedAt: json['approved_at']?.toString(),
      remarks: json['remarks']?.toString(),
      createdBy: JsonModel.nullableInt(json['created_by']),
      updatedBy: JsonModel.nullableInt(json['updated_by']),
      isActive: json['is_active'] == null
          ? null
          : JsonModel.boolOf(json['is_active']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
  @override
  String toString() => 'Qc Inspection';


  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (companyId != null) 'company_id': companyId,
    if (branchId != null) 'branch_id': branchId,
    if (locationId != null) 'location_id': locationId,
    if (financialYearId != null) 'financial_year_id': financialYearId,
    if (documentSeriesId != null) 'document_series_id': documentSeriesId,
    if (inspectionNo != null) 'inspection_no': inspectionNo,
    if (inspectionDate != null) 'inspection_date': inspectionDate,
    if (qcPlanId != null) 'qc_plan_id': qcPlanId,
    if (inspectionScope != null) 'inspection_scope': inspectionScope,
    if (sourceDocumentType != null) 'source_document_type': sourceDocumentType,
    if (sourceDocumentId != null) 'source_document_id': sourceDocumentId,
    if (sourceLineId != null) 'source_line_id': sourceLineId,
    if (itemId != null) 'item_id': itemId,
    if (uomId != null) 'uom_id': uomId,
    if (warehouseId != null) 'warehouse_id': warehouseId,
    if (batchId != null) 'batch_id': batchId,
    if (serialId != null) 'serial_id': serialId,
    if (lotNo != null) 'lot_no': lotNo,
    if (sampleSize != null) 'sample_size': sampleSize,
    if (inspectedQty != null) 'inspected_qty': inspectedQty,
    if (acceptedQty != null) 'accepted_qty': acceptedQty,
    if (rejectedQty != null) 'rejected_qty': rejectedQty,
    if (holdQty != null) 'hold_qty': holdQty,
    if (reworkQty != null) 'rework_qty': reworkQty,
    if (inspectionStatus != null) 'inspection_status': inspectionStatus,
    if (finalResult != null) 'final_result': finalResult,
    if (inspectedBy != null) 'inspected_by': inspectedBy,
    if (inspectedAt != null) 'inspected_at': inspectedAt,
    if (approvedBy != null) 'approved_by': approvedBy,
    if (approvedAt != null) 'approved_at': approvedAt,
    if (remarks != null) 'remarks': remarks,
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (isActive != null) 'is_active': isActive,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
