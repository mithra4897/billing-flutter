import '../../screen.dart';

class CrmLeadActivityModel implements JsonModel {
  const CrmLeadActivityModel({
    this.id,
    this.leadId,
    this.activityType,
    this.activityDatetime,
    this.notes,
    this.nextFollowup,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final int? leadId;
  final String? activityType;
  final String? activityDatetime;
  final String? notes;
  final String? nextFollowup;
  final int? createdBy;
  final String? createdAt;
  final String? updatedAt;

  factory CrmLeadActivityModel.fromJson(Map<String, dynamic> json) {
    return CrmLeadActivityModel(
      id: ModelValue.nullableInt(json['id']),
      leadId: ModelValue.nullableInt(json['lead_id']),
      activityType: json['activity_type']?.toString(),
      activityDatetime: json['activity_datetime']?.toString(),
      notes: json['notes']?.toString(),
      nextFollowup: json['next_followup']?.toString(),
      createdBy: ModelValue.nullableInt(json['created_by']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (leadId != null) 'lead_id': leadId,
    if (activityType != null) 'activity_type': activityType,
    if (activityDatetime != null) 'activity_datetime': activityDatetime,
    if (notes != null) 'notes': notes,
    if (nextFollowup != null) 'next_followup': nextFollowup,
    if (createdBy != null) 'created_by': createdBy,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
