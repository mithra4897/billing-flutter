import '../common/json_model.dart';
import '../common/model_value.dart';

class ProjectTaskModel implements JsonModel {
  const ProjectTaskModel({
    this.id,
    this.projectId,
    this.taskCode,
    this.taskName,
    this.description,
    this.assignedEmployeeId,
    this.plannedStartDate,
    this.plannedEndDate,
    this.actualStartDate,
    this.actualEndDate,
    this.estimatedHours,
    this.actualHours,
    this.estimatedCost,
    this.actualCost,
    this.progressPercent,
    this.taskStatus,
    this.isBillable,
    this.remarks,
    this.raw,
  });

  final int? id;
  final int? projectId;
  final String? taskCode;
  final String? taskName;
  final String? description;
  final int? assignedEmployeeId;
  final String? plannedStartDate;
  final String? plannedEndDate;
  final String? actualStartDate;
  final String? actualEndDate;
  final double? estimatedHours;
  final double? actualHours;
  final double? estimatedCost;
  final double? actualCost;
  final double? progressPercent;
  final String? taskStatus;
  final bool? isBillable;
  final String? remarks;
  final Map<String, dynamic>? raw;

  factory ProjectTaskModel.fromJson(Map<String, dynamic> json) {
    return ProjectTaskModel(
      id: ModelValue.nullableInt(json['id']),
      projectId: ModelValue.nullableInt(json['project_id']),
      taskCode: json['task_code']?.toString(),
      taskName: json['task_name']?.toString(),
      description: json['description']?.toString(),
      assignedEmployeeId: ModelValue.nullableInt(json['assigned_employee_id']),
      plannedStartDate: json['planned_start_date']?.toString(),
      plannedEndDate: json['planned_end_date']?.toString(),
      actualStartDate: json['actual_start_date']?.toString(),
      actualEndDate: json['actual_end_date']?.toString(),
      estimatedHours: ModelValue.nullableDouble(json['estimated_hours']),
      actualHours: ModelValue.nullableDouble(json['actual_hours']),
      estimatedCost: ModelValue.nullableDouble(json['estimated_cost']),
      actualCost: ModelValue.nullableDouble(json['actual_cost']),
      progressPercent: ModelValue.nullableDouble(json['progress_percent']),
      taskStatus: json['task_status']?.toString(),
      isBillable: json['is_billable'] == null
          ? null
          : ModelValue.boolOf(json['is_billable']),
      remarks: json['remarks']?.toString(),
      raw: json,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    if (projectId != null) 'project_id': projectId,
    if (taskCode != null) 'task_code': taskCode,
    if (taskName != null) 'task_name': taskName,
    if (description != null) 'description': description,
    if (assignedEmployeeId != null) 'assigned_employee_id': assignedEmployeeId,
    if (plannedStartDate != null) 'planned_start_date': plannedStartDate,
    if (plannedEndDate != null) 'planned_end_date': plannedEndDate,
    if (actualStartDate != null) 'actual_start_date': actualStartDate,
    if (actualEndDate != null) 'actual_end_date': actualEndDate,
    if (estimatedHours != null) 'estimated_hours': estimatedHours,
    if (actualHours != null) 'actual_hours': actualHours,
    if (estimatedCost != null) 'estimated_cost': estimatedCost,
    if (actualCost != null) 'actual_cost': actualCost,
    if (progressPercent != null) 'progress_percent': progressPercent,
    if (taskStatus != null) 'task_status': taskStatus,
    if (isBillable != null) 'is_billable': isBillable,
    if (remarks != null) 'remarks': remarks,
  };
}
