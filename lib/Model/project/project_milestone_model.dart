import '../common/json_model.dart';
import '../common/model_value.dart';

class ProjectMilestoneModel implements JsonModel {
  const ProjectMilestoneModel({
    this.id,
    this.projectId,
    this.milestoneName,
    this.targetDate,
    this.completionDate,
    this.milestoneAmount,
    this.milestoneStatus,
    this.remarks,
    this.raw,
  });

  final int? id;
  final int? projectId;
  final String? milestoneName;
  final String? targetDate;
  final String? completionDate;
  final double? milestoneAmount;
  final String? milestoneStatus;
  final String? remarks;
  final Map<String, dynamic>? raw;

  factory ProjectMilestoneModel.fromJson(Map<String, dynamic> json) {
    return ProjectMilestoneModel(
      id: ModelValue.nullableInt(json['id']),
      projectId: ModelValue.nullableInt(json['project_id']),
      milestoneName: json['milestone_name']?.toString(),
      targetDate: json['target_date']?.toString(),
      completionDate: json['completion_date']?.toString(),
      milestoneAmount: ModelValue.nullableDouble(json['milestone_amount']),
      milestoneStatus: json['milestone_status']?.toString(),
      remarks: json['remarks']?.toString(),
      raw: json,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    if (projectId != null) 'project_id': projectId,
    if (milestoneName != null) 'milestone_name': milestoneName,
    if (targetDate != null) 'target_date': targetDate,
    if (completionDate != null) 'completion_date': completionDate,
    if (milestoneAmount != null) 'milestone_amount': milestoneAmount,
    if (milestoneStatus != null) 'milestone_status': milestoneStatus,
    if (remarks != null) 'remarks': remarks,
  };
}
