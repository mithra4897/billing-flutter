import '../common/json_model.dart';
import '../common/model_value.dart';

class ProjectResourceUsageModel implements JsonModel {
  const ProjectResourceUsageModel({
    this.id,
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
    this.raw,
  });

  final int? id;
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
  final Map<String, dynamic>? raw;

  factory ProjectResourceUsageModel.fromJson(Map<String, dynamic> json) {
    return ProjectResourceUsageModel(
      id: ModelValue.nullableInt(json['id']),
      projectId: ModelValue.nullableInt(json['project_id']),
      projectTaskId: ModelValue.nullableInt(json['project_task_id']),
      assetId: ModelValue.nullableInt(json['asset_id']),
      resourceName: json['resource_name']?.toString(),
      usageDate: json['usage_date']?.toString(),
      usageHours: ModelValue.nullableDouble(json['usage_hours']),
      usageQty: ModelValue.nullableDouble(json['usage_qty']),
      unitCost: ModelValue.nullableDouble(json['unit_cost']),
      totalCost: ModelValue.nullableDouble(json['total_cost']),
      voucherId: ModelValue.nullableInt(json['voucher_id']),
      remarks: json['remarks']?.toString(),
      raw: json,
    );
  }

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
