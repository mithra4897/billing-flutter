import '../../screen.dart';

class ProjectTimesheetModel extends JsonModel {
  const ProjectTimesheetModel({
    super.id,
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
  });
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

  factory ProjectTimesheetModel.fromJson(Map<String, dynamic> json) {
    return ProjectTimesheetModel(
      id: JsonModel.nullableInt(json['id']),
      projectId: JsonModel.nullableInt(json['project_id']),
      projectTaskId: JsonModel.nullableInt(json['project_task_id']),
      employeeId: JsonModel.nullableInt(json['employee_id']),
      workDate: json['work_date']?.toString(),
      hoursWorked: JsonModel.nullableDouble(json['hours_worked']),
      hourlyCost: JsonModel.nullableDouble(json['hourly_cost']),
      billableRate: JsonModel.nullableDouble(json['billable_rate']),
      costAmount: JsonModel.nullableDouble(json['cost_amount']),
      billableAmount: JsonModel.nullableDouble(json['billable_amount']),
      voucherId: JsonModel.nullableInt(json['voucher_id']),
      timesheetStatus: json['timesheet_status']?.toString(),
      notes: json['notes']?.toString(),
    );
  }
  @override
  String toString() => JsonModel.combineValues([
    notes,
    workDate,
    hoursWorked,
    timesheetStatus,
  ], defaultValue: 'Project Timesheet');


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
