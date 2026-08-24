import '../../screen.dart';

class CrmLeadModel extends JsonModel {
  const CrmLeadModel({
    super.id,
    this.companyId,
    this.leadName,
    this.companyName,
    this.mobile,
    this.email,
    this.sourceId,
    this.source,
    this.assignedTo,
    this.assignedUser,
    this.leadStatus,
    this.probabilityPercent,
    this.remarks,
    this.createdBy,
    this.creator,
    this.createdAt,
    this.updatedAt,
    this.activities = const <Map<String, dynamic>>[],
    this.activitiesCount,
  });

  final int? companyId;
  final String? leadName;
  final String? companyName;
  final String? mobile;
  final String? email;
  final int? sourceId;
  final Map<String, dynamic>? source;
  final int? assignedTo;
  final Map<String, dynamic>? assignedUser;
  final String? leadStatus;
  final double? probabilityPercent;
  final String? remarks;
  final int? createdBy;
  final Map<String, dynamic>? creator;
  final String? createdAt;
  final String? updatedAt;
  final List<Map<String, dynamic>> activities;
  final int? activitiesCount;

  factory CrmLeadModel.fromJson(Map<String, dynamic> json) {
    return CrmLeadModel(
      id: JsonModel.nullableInt(json['id']),
      companyId: JsonModel.nullableInt(json['company_id']),
      leadName: json['lead_name']?.toString(),
      companyName: json['company_name']?.toString(),
      mobile: json['mobile']?.toString(),
      email: json['email']?.toString(),
      sourceId: JsonModel.nullableInt(json['source_id']),
      source: JsonModel.mapOf(json['source']),
      assignedTo: JsonModel.nullableInt(json['assigned_to']),
      assignedUser: JsonModel.mapOf(json['assigned_user']),
      leadStatus: json['lead_status']?.toString(),
      probabilityPercent: JsonModel.nullableDouble(json['probability_percent']),
      remarks: json['remarks']?.toString(),
      createdBy: JsonModel.nullableInt(json['created_by']),
      creator: JsonModel.mapOf(json['creator']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      activities: JsonModel.mapListOf(json['activities']),
      activitiesCount: JsonModel.nullableInt(json['activities_count']),
    );
  }

  @override
  String toString() => JsonModel.combineValues([
    leadName,
    companyName,
    mobile,
  ], defaultValue: 'CRM Lead');

  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (companyId != null) 'company_id': companyId,
    if (leadName != null) 'lead_name': leadName,
    if (companyName != null) 'company_name': companyName,
    if (mobile != null) 'mobile': mobile,
    if (email != null) 'email': email,
    if (sourceId != null) 'source_id': sourceId,
    if (source != null) 'source': source,
    if (assignedTo != null) 'assigned_to': assignedTo,
    if (assignedUser != null) 'assigned_user': assignedUser,
    if (leadStatus != null) 'lead_status': leadStatus,
    if (probabilityPercent != null) 'probability_percent': probabilityPercent,
    if (remarks != null) 'remarks': remarks,
    if (createdBy != null) 'created_by': createdBy,
    if (creator != null) 'creator': creator,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
    'activities': activities,
    if (activitiesCount != null) 'activities_count': activitiesCount,
  };
}
