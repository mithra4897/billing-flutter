import '../common/json_model.dart';
import '../common/model_value.dart';

class ProjectTimesheetModel implements JsonModel {
  const ProjectTimesheetModel({
    this.id,
    this.projectId,
    this.projectTaskId,
    this.employeeId,
    this.workDate,
    this.hoursWorked,
    this.hourlyCost,
    this.billableRate,
    this.costAmount,
    this.billableAmount,
    this.voucherId,
    this.timesheetStatus,
    this.notes,
    this.raw,
  });

  final int? id;
  final int? projectId;
  final int? projectTaskId;
  final int? employeeId;
  final String? workDate;
  final double? hoursWorked;
  final double? hourlyCost;
  final double? billableRate;
  final double? costAmount;
  final double? billableAmount;
  final int? voucherId;
  final String? timesheetStatus;
  final String? notes;
  final Map<String, dynamic>? raw;

  factory ProjectTimesheetModel.fromJson(Map<String, dynamic> json) {
    return ProjectTimesheetModel(
      id: ModelValue.nullableInt(json['id']),
      projectId: ModelValue.nullableInt(json['project_id']),
      projectTaskId: ModelValue.nullableInt(json['project_task_id']),
      employeeId: ModelValue.nullableInt(json['employee_id']),
      workDate: json['work_date']?.toString(),
      hoursWorked: ModelValue.nullableDouble(json['hours_worked']),
      hourlyCost: ModelValue.nullableDouble(json['hourly_cost']),
      billableRate: ModelValue.nullableDouble(json['billable_rate']),
      costAmount: ModelValue.nullableDouble(json['cost_amount']),
      billableAmount: ModelValue.nullableDouble(json['billable_amount']),
      voucherId: ModelValue.nullableInt(json['voucher_id']),
      timesheetStatus: json['timesheet_status']?.toString(),
      notes: json['notes']?.toString(),
      raw: json,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    if (projectId != null) 'project_id': projectId,
    if (projectTaskId != null) 'project_task_id': projectTaskId,
    if (employeeId != null) 'employee_id': employeeId,
    if (workDate != null) 'work_date': workDate,
    if (hoursWorked != null) 'hours_worked': hoursWorked,
    if (hourlyCost != null) 'hourly_cost': hourlyCost,
    if (billableRate != null) 'billable_rate': billableRate,
    if (costAmount != null) 'cost_amount': costAmount,
    if (billableAmount != null) 'billable_amount': billableAmount,
    if (voucherId != null) 'voucher_id': voucherId,
    if (timesheetStatus != null) 'timesheet_status': timesheetStatus,
    if (notes != null) 'notes': notes,
  };
}
