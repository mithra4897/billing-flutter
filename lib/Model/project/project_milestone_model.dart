import '../../screen.dart';

class ProjectMilestoneModel extends JsonModel {
  const ProjectMilestoneModel({
    super.id,
    this.projectId,
    this.milestoneName,
    this.targetDate,
    this.completionDate,
    this.milestoneAmount,
    this.milestoneStatus,
    this.remarks,
  });
  final int? projectId;
  final String? milestoneName;
  final String? targetDate;
  final String? completionDate;
  final double? milestoneAmount;
  final String? milestoneStatus;
  final String? remarks;

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
    );
  }
  @override
  String toString() => 'Project Milestone';


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
