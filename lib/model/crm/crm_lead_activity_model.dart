import '../../screen.dart';

class CrmLeadActivityModel extends JsonModel {
  const CrmLeadActivityModel({
    super.id,
    this.leadId,
    this.activityType,
    this.activityDatetime,
    this.notes,
    this.nextFollowup,
    this.status,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  final int? leadId;
  final String? activityType;
  final String? activityDatetime;
  final String? notes;
  final String? nextFollowup;
  final String? status;
  final int? createdBy;
  final String? createdAt;
  final String? updatedAt;

  factory CrmLeadActivityModel.fromJson(Map<String, dynamic> json) {
    return CrmLeadActivityModel(
      id: JsonModel.nullableInt(json['id']),
      leadId: JsonModel.nullableInt(json['lead_id']),
      activityType: json['activity_type']?.toString(),
      activityDatetime: json['activity_datetime']?.toString(),
      notes: json['notes']?.toString(),
      nextFollowup: json['next_followup']?.toString(),
      status: json['status']?.toString(),
      createdBy: JsonModel.nullableInt(json['created_by']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  @override
  String toString() => JsonModel.combineValues([
    activityType,
    notes,
  ], defaultValue: 'CRM Lead Activity');

  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (leadId != null) 'lead_id': leadId,
    if (activityType != null) 'activity_type': activityType,
    if (activityDatetime != null) 'activity_datetime': activityDatetime,
    if (notes != null) 'notes': notes,
    if (nextFollowup != null) 'next_followup': nextFollowup,
    if (status != null) 'status': status,
    if (createdBy != null) 'created_by': createdBy,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
