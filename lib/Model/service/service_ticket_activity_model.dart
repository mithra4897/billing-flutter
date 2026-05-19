import '../../screen.dart';

class ServiceTicketActivityModel extends JsonModel {
  const ServiceTicketActivityModel({
    super.id,
    this.serviceTicketId,
    this.activityType,
    this.activityDatetime,
    this.activityNotes,
    this.nextFollowupDatetime,
    this.visibility,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });
  final int? serviceTicketId;
  final String? activityType;
  final String? activityDatetime;
  final String? activityNotes;
  final String? nextFollowupDatetime;
  final String? visibility;
  final int? createdBy;
  final String? createdAt;
  final String? updatedAt;

  factory ServiceTicketActivityModel.fromJson(Map<String, dynamic> json) {
    return ServiceTicketActivityModel(
      id: JsonModel.nullableInt(json['id']),
      serviceTicketId: JsonModel.nullableInt(json['service_ticket_id']),
      activityType: json['activity_type']?.toString(),
      activityDatetime: json['activity_datetime']?.toString(),
      activityNotes: json['activity_notes']?.toString(),
      nextFollowupDatetime: json['next_followup_datetime']?.toString(),
      visibility: json['visibility']?.toString(),
      createdBy: JsonModel.nullableInt(json['created_by']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
  @override
  String toString() => 'Service Ticket Activity';


  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (serviceTicketId != null) 'service_ticket_id': serviceTicketId,
    if (activityType != null) 'activity_type': activityType,
    if (activityDatetime != null) 'activity_datetime': activityDatetime,
    if (activityNotes != null) 'activity_notes': activityNotes,
    if (nextFollowupDatetime != null)
      'next_followup_datetime': nextFollowupDatetime,
    if (visibility != null) 'visibility': visibility,
    if (createdBy != null) 'created_by': createdBy,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
