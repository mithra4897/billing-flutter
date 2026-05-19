import '../../screen.dart';

class ProjectResourceUsageModel extends JsonModel {
  const ProjectResourceUsageModel({
    super.id,
    this.projectId,
    this.projectTaskId,
    this.assetId,
    this.resourceName,
    this.usageDate,
    this.usageHours,
    this.usageQty,
    this.unitCost,
    this.totalCost,
    this.voucherId,
    this.remarks,
  });
  final int? projectId;
  final int? projectTaskId;
  final int? assetId;
  final String? resourceName;
  final String? usageDate;
  final double? usageHours;
  final double? usageQty;
  final double? unitCost;
  final double? totalCost;
  final int? voucherId;
  final String? remarks;

  factory ProjectResourceUsageModel.fromJson(Map<String, dynamic> json) {
    return ProjectResourceUsageModel(
      id: JsonModel.nullableInt(json['id']),
      projectId: JsonModel.nullableInt(json['project_id']),
      projectTaskId: JsonModel.nullableInt(json['project_task_id']),
      assetId: JsonModel.nullableInt(json['asset_id']),
      resourceName: json['resource_name']?.toString(),
      usageDate: json['usage_date']?.toString(),
      usageHours: JsonModel.nullableDouble(json['usage_hours']),
      usageQty: JsonModel.nullableDouble(json['usage_qty']),
      unitCost: JsonModel.nullableDouble(json['unit_cost']),
      totalCost: JsonModel.nullableDouble(json['total_cost']),
      voucherId: JsonModel.nullableInt(json['voucher_id']),
      remarks: json['remarks']?.toString(),
    );
  }
  @override
  String toString() => 'Project Resource Usage';


  @override
  Map<String, dynamic> toJson() => {
    if (projectId != null) 'project_id': projectId,
    if (projectTaskId != null) 'project_task_id': projectTaskId,
    if (assetId != null) 'asset_id': assetId,
    if (resourceName != null) 'resource_name': resourceName,
    if (usageDate != null) 'usage_date': usageDate,
    if (usageHours != null) 'usage_hours': usageHours,
    if (usageQty != null) 'usage_qty': usageQty,
    if (unitCost != null) 'unit_cost': unitCost,
    if (totalCost != null) 'total_cost': totalCost,
    if (voucherId != null) 'voucher_id': voucherId,
    if (remarks != null) 'remarks': remarks,
  };
}
