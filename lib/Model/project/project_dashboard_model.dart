import '../../screen.dart';

class ProjectDashboardModel implements JsonModel {
  const ProjectDashboardModel({
    this.projectId,
    this.projectCode,
    this.projectName,
    this.budgetAmount,
    this.actualCost,
    this.budgetVariance,
    this.billedAmount,
    this.profitability,
    this.costBreakup,
    this.taskSummary,
    this.milestoneSummary,
    this.progressPercent,
  });

  final int? projectId;
  final String? projectCode;
  final String? projectName;
  final double? budgetAmount;
  final double? actualCost;
  final double? budgetVariance;
  final double? billedAmount;
  final double? profitability;
  final Map<String, dynamic>? costBreakup;
  final Map<String, dynamic>? taskSummary;
  final Map<String, dynamic>? milestoneSummary;
  final double? progressPercent;

  factory ProjectDashboardModel.fromJson(Map<String, dynamic> json) {
    return ProjectDashboardModel(
      projectId: ModelValue.nullableInt(json['project_id']),
      projectCode: json['project_code']?.toString(),
      projectName: json['project_name']?.toString(),
      budgetAmount: ModelValue.nullableDouble(json['budget_amount']),
      actualCost: ModelValue.nullableDouble(json['actual_cost']),
      budgetVariance: ModelValue.nullableDouble(json['budget_variance']),
      billedAmount: ModelValue.nullableDouble(json['billed_amount']),
      profitability: ModelValue.nullableDouble(json['profitability']),
      costBreakup: _map(json['cost_breakup']),
      taskSummary: _map(json['task_summary']),
      milestoneSummary: _map(json['milestone_summary']),
      progressPercent: ModelValue.nullableDouble(json['progress_percent']),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    if (projectId != null) 'project_id': projectId,
    if (projectCode != null) 'project_code': projectCode,
    if (projectName != null) 'project_name': projectName,
    if (budgetAmount != null) 'budget_amount': budgetAmount,
    if (actualCost != null) 'actual_cost': actualCost,
    if (budgetVariance != null) 'budget_variance': budgetVariance,
    if (billedAmount != null) 'billed_amount': billedAmount,
    if (profitability != null) 'profitability': profitability,
    if (costBreakup != null) 'cost_breakup': costBreakup,
    if (taskSummary != null) 'task_summary': taskSummary,
    if (milestoneSummary != null) 'milestone_summary': milestoneSummary,
    if (progressPercent != null) 'progress_percent': progressPercent,
  };

  static Map<String, dynamic>? _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }
}
