import '../../screen.dart';

class MaintenanceRequestModel extends JsonModel {
  const MaintenanceRequestModel({
    super.id,
    this.companyId,
    this.branchId,
    this.locationId,
    this.requestNo,
    this.requestDate,
    this.assetId,
    this.maintenancePlanId,
    this.requestType,
    this.priorityLevel,
    this.issueTitle,
    this.issueDescription,
    this.requestedBy,
    this.requestStatus,
    this.approvedBy,
    this.approvedAt,
    this.targetCompletionDate,
    this.remarks,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  });
  final int? companyId;
  final int? branchId;
  final int? locationId;
  final String? requestNo;
  final String? requestDate;
  final int? assetId;
  final int? maintenancePlanId;
  final String? requestType;
  final int? priorityLevel;
  final String? issueTitle;
  final String? issueDescription;
  final int? requestedBy;
  final String? requestStatus;
  final int? approvedBy;
  final String? approvedAt;
  final String? targetCompletionDate;
  final String? remarks;
  final int? createdBy;
  final int? updatedBy;
  final String? createdAt;
  final String? updatedAt;

  factory MaintenanceRequestModel.fromJson(Map<String, dynamic> json) {
    return MaintenanceRequestModel(
      id: JsonModel.nullableInt(json['id']),
      companyId: JsonModel.nullableInt(json['company_id']),
      branchId: JsonModel.nullableInt(json['branch_id']),
      locationId: JsonModel.nullableInt(json['location_id']),
      requestNo: json['request_no']?.toString(),
      requestDate: json['request_date']?.toString(),
      assetId: JsonModel.nullableInt(json['asset_id']),
      maintenancePlanId: JsonModel.nullableInt(json['maintenance_plan_id']),
      requestType: json['request_type']?.toString(),
      priorityLevel: JsonModel.nullableInt(json['priority_level']),
      issueTitle: json['issue_title']?.toString(),
      issueDescription: json['issue_description']?.toString(),
      requestedBy: JsonModel.nullableInt(json['requested_by']),
      requestStatus: json['request_status']?.toString(),
      approvedBy: JsonModel.nullableInt(json['approved_by']),
      approvedAt: json['approved_at']?.toString(),
      targetCompletionDate: json['target_completion_date']?.toString(),
      remarks: json['remarks']?.toString(),
      createdBy: JsonModel.nullableInt(json['created_by']),
      updatedBy: JsonModel.nullableInt(json['updated_by']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
  @override
  String toString() => 'Maintenance Request';


  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (companyId != null) 'company_id': companyId,
    if (branchId != null) 'branch_id': branchId,
    if (locationId != null) 'location_id': locationId,
    if (requestNo != null) 'request_no': requestNo,
    if (requestDate != null) 'request_date': requestDate,
    if (assetId != null) 'asset_id': assetId,
    if (maintenancePlanId != null) 'maintenance_plan_id': maintenancePlanId,
    if (requestType != null) 'request_type': requestType,
    if (priorityLevel != null) 'priority_level': priorityLevel,
    if (issueTitle != null) 'issue_title': issueTitle,
    if (issueDescription != null) 'issue_description': issueDescription,
    if (requestedBy != null) 'requested_by': requestedBy,
    if (requestStatus != null) 'request_status': requestStatus,
    if (approvedBy != null) 'approved_by': approvedBy,
    if (approvedAt != null) 'approved_at': approvedAt,
    if (targetCompletionDate != null)
      'target_completion_date': targetCompletionDate,
    if (remarks != null) 'remarks': remarks,
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
