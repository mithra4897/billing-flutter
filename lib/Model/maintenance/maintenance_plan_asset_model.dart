import '../../screen.dart';

class MaintenancePlanAssetModel extends JsonModel {
  const MaintenancePlanAssetModel({
    super.id,
    this.maintenancePlanId,
    this.assetId,
    this.lastServiceDate,
    this.nextServiceDueDate,
    this.runningHoursThreshold,
    this.currentRunningHours,
    this.assignedVendorPartyId,
    this.assignedInternalTeam,
    this.isActive,
    this.remarks,
    this.createdAt,
    this.updatedAt,
  });
  final int? maintenancePlanId;
  final int? assetId;
  final String? lastServiceDate;
  final String? nextServiceDueDate;
  final double? runningHoursThreshold;
  final double? currentRunningHours;
  final int? assignedVendorPartyId;
  final String? assignedInternalTeam;
  final bool? isActive;
  final String? remarks;
  final String? createdAt;
  final String? updatedAt;

  factory MaintenancePlanAssetModel.fromJson(Map<String, dynamic> json) {
    return MaintenancePlanAssetModel(
      id: JsonModel.nullableInt(json['id']),
      maintenancePlanId: JsonModel.nullableInt(json['maintenance_plan_id']),
      assetId: JsonModel.nullableInt(json['asset_id']),
      lastServiceDate: json['last_service_date']?.toString(),
      nextServiceDueDate: json['next_service_due_date']?.toString(),
      runningHoursThreshold: JsonModel.nullableDouble(
        json['running_hours_threshold'],
      ),
      currentRunningHours: JsonModel.nullableDouble(
        json['current_running_hours'],
      ),
      assignedVendorPartyId: JsonModel.nullableInt(
        json['assigned_vendor_party_id'],
      ),
      assignedInternalTeam: json['assigned_internal_team']?.toString(),
      isActive: json['is_active'] == null
          ? null
          : JsonModel.boolOf(json['is_active']),
      remarks: json['remarks']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
  @override
  String toString() => 'Maintenance Plan Asset';


  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (maintenancePlanId != null) 'maintenance_plan_id': maintenancePlanId,
    if (assetId != null) 'asset_id': assetId,
    if (lastServiceDate != null) 'last_service_date': lastServiceDate,
    if (nextServiceDueDate != null) 'next_service_due_date': nextServiceDueDate,
    if (runningHoursThreshold != null)
      'running_hours_threshold': runningHoursThreshold,
    if (currentRunningHours != null)
      'current_running_hours': currentRunningHours,
    if (assignedVendorPartyId != null)
      'assigned_vendor_party_id': assignedVendorPartyId,
    if (assignedInternalTeam != null)
      'assigned_internal_team': assignedInternalTeam,
    if (isActive != null) 'is_active': isActive,
    if (remarks != null) 'remarks': remarks,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
