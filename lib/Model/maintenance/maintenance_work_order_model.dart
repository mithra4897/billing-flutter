import '../../screen.dart';

class MaintenanceWorkOrderModel extends JsonModel {
  const MaintenanceWorkOrderModel({
    super.id,
    this.companyId,
    this.branchId,
    this.locationId,
    this.financialYearId,
    this.documentSeriesId,
    this.workOrderNo,
    this.workOrderDate,
    this.maintenanceRequestId,
    this.assetId,
    this.maintenancePlanId,
    this.workOrderType,
    this.executionMode,
    this.vendorPartyId,
    this.assignedTechnician,
    this.assignedTeam,
    this.workOrderStatus,
    this.faultDescription,
    this.actionTaken,
    this.resolutionSummary,
    this.plannedStartDatetime,
    this.plannedEndDatetime,
    this.actualStartDatetime,
    this.actualEndDatetime,
    this.downtimeMinutes,
    this.laborCost,
    this.spareCost,
    this.externalServiceCost,
    this.otherCost,
    this.totalCost,
    this.voucherId,
    this.remarks,
    this.approvedBy,
    this.approvedAt,
    this.closedBy,
    this.closedAt,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  });
  final int? companyId;
  final int? branchId;
  final int? locationId;
  final int? financialYearId;
  final int? documentSeriesId;
  final String? workOrderNo;
  final String? workOrderDate;
  final int? maintenanceRequestId;
  final int? assetId;
  final int? maintenancePlanId;
  final String? workOrderType;
  final String? executionMode;
  final int? vendorPartyId;
  final String? assignedTechnician;
  final String? assignedTeam;
  final String? workOrderStatus;
  final String? faultDescription;
  final String? actionTaken;
  final String? resolutionSummary;
  final String? plannedStartDatetime;
  final String? plannedEndDatetime;
  final String? actualStartDatetime;
  final String? actualEndDatetime;
  final double? downtimeMinutes;
  final double? laborCost;
  final double? spareCost;
  final double? externalServiceCost;
  final double? otherCost;
  final double? totalCost;
  final int? voucherId;
  final String? remarks;
  final int? approvedBy;
  final String? approvedAt;
  final int? closedBy;
  final String? closedAt;
  final int? createdBy;
  final int? updatedBy;
  final String? createdAt;
  final String? updatedAt;

  factory MaintenanceWorkOrderModel.fromJson(Map<String, dynamic> json) {
    return MaintenanceWorkOrderModel(
      id: JsonModel.nullableInt(json['id']),
      companyId: JsonModel.nullableInt(json['company_id']),
      branchId: JsonModel.nullableInt(json['branch_id']),
      locationId: JsonModel.nullableInt(json['location_id']),
      financialYearId: JsonModel.nullableInt(json['financial_year_id']),
      documentSeriesId: JsonModel.nullableInt(json['document_series_id']),
      workOrderNo: json['work_order_no']?.toString(),
      workOrderDate: json['work_order_date']?.toString(),
      maintenanceRequestId: JsonModel.nullableInt(
        json['maintenance_request_id'],
      ),
      assetId: JsonModel.nullableInt(json['asset_id']),
      maintenancePlanId: JsonModel.nullableInt(json['maintenance_plan_id']),
      workOrderType: json['work_order_type']?.toString(),
      executionMode: json['execution_mode']?.toString(),
      vendorPartyId: JsonModel.nullableInt(json['vendor_party_id']),
      assignedTechnician: json['assigned_technician']?.toString(),
      assignedTeam: json['assigned_team']?.toString(),
      workOrderStatus: json['work_order_status']?.toString(),
      faultDescription: json['fault_description']?.toString(),
      actionTaken: json['action_taken']?.toString(),
      resolutionSummary: json['resolution_summary']?.toString(),
      plannedStartDatetime: json['planned_start_datetime']?.toString(),
      plannedEndDatetime: json['planned_end_datetime']?.toString(),
      actualStartDatetime: json['actual_start_datetime']?.toString(),
      actualEndDatetime: json['actual_end_datetime']?.toString(),
      downtimeMinutes: JsonModel.nullableDouble(json['downtime_minutes']),
      laborCost: JsonModel.nullableDouble(json['labor_cost']),
      spareCost: JsonModel.nullableDouble(json['spare_cost']),
      externalServiceCost: JsonModel.nullableDouble(
        json['external_service_cost'],
      ),
      otherCost: JsonModel.nullableDouble(json['other_cost']),
      totalCost: JsonModel.nullableDouble(json['total_cost']),
      voucherId: JsonModel.nullableInt(json['voucher_id']),
      remarks: json['remarks']?.toString(),
      approvedBy: JsonModel.nullableInt(json['approved_by']),
      approvedAt: json['approved_at']?.toString(),
      closedBy: JsonModel.nullableInt(json['closed_by']),
      closedAt: json['closed_at']?.toString(),
      createdBy: JsonModel.nullableInt(json['created_by']),
      updatedBy: JsonModel.nullableInt(json['updated_by']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
  @override
  String toString() => 'Maintenance Work Order';


  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (companyId != null) 'company_id': companyId,
    if (branchId != null) 'branch_id': branchId,
    if (locationId != null) 'location_id': locationId,
    if (financialYearId != null) 'financial_year_id': financialYearId,
    if (documentSeriesId != null) 'document_series_id': documentSeriesId,
    if (workOrderNo != null) 'work_order_no': workOrderNo,
    if (workOrderDate != null) 'work_order_date': workOrderDate,
    if (maintenanceRequestId != null)
      'maintenance_request_id': maintenanceRequestId,
    if (assetId != null) 'asset_id': assetId,
    if (maintenancePlanId != null) 'maintenance_plan_id': maintenancePlanId,
    if (workOrderType != null) 'work_order_type': workOrderType,
    if (executionMode != null) 'execution_mode': executionMode,
    if (vendorPartyId != null) 'vendor_party_id': vendorPartyId,
    if (assignedTechnician != null) 'assigned_technician': assignedTechnician,
    if (assignedTeam != null) 'assigned_team': assignedTeam,
    if (workOrderStatus != null) 'work_order_status': workOrderStatus,
    if (faultDescription != null) 'fault_description': faultDescription,
    if (actionTaken != null) 'action_taken': actionTaken,
    if (resolutionSummary != null) 'resolution_summary': resolutionSummary,
    if (plannedStartDatetime != null)
      'planned_start_datetime': plannedStartDatetime,
    if (plannedEndDatetime != null) 'planned_end_datetime': plannedEndDatetime,
    if (actualStartDatetime != null)
      'actual_start_datetime': actualStartDatetime,
    if (actualEndDatetime != null) 'actual_end_datetime': actualEndDatetime,
    if (downtimeMinutes != null) 'downtime_minutes': downtimeMinutes,
    if (laborCost != null) 'labor_cost': laborCost,
    if (spareCost != null) 'spare_cost': spareCost,
    if (externalServiceCost != null)
      'external_service_cost': externalServiceCost,
    if (otherCost != null) 'other_cost': otherCost,
    if (totalCost != null) 'total_cost': totalCost,
    if (voucherId != null) 'voucher_id': voucherId,
    if (remarks != null) 'remarks': remarks,
    if (approvedBy != null) 'approved_by': approvedBy,
    if (approvedAt != null) 'approved_at': approvedAt,
    if (closedBy != null) 'closed_by': closedBy,
    if (closedAt != null) 'closed_at': closedAt,
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
