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
    this.assignedTo,
    this.leadStatus,
    this.remarks,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.activities = const <Map<String, dynamic>>[],
  });

  final int? companyId;
  final String? leadName;
  final String? companyName;
  final String? mobile;
  final String? email;
  final int? sourceId;
  final int? assignedTo;
  final String? leadStatus;
  final String? remarks;
  final int? createdBy;
  final String? createdAt;
  final String? updatedAt;
  final List<Map<String, dynamic>> activities;

  factory CrmLeadModel.fromJson(Map<String, dynamic> json) {
    return CrmLeadModel(
      id: JsonModel.nullableInt(json['id']),
      companyId: JsonModel.nullableInt(json['company_id']),
      leadName: json['lead_name']?.toString(),
      companyName: json['company_name']?.toString(),
      mobile: json['mobile']?.toString(),
      email: json['email']?.toString(),
      sourceId: JsonModel.nullableInt(json['source_id']),
      assignedTo: JsonModel.nullableInt(json['assigned_to']),
      leadStatus: json['lead_status']?.toString(),
      remarks: json['remarks']?.toString(),
      createdBy: JsonModel.nullableInt(json['created_by']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      activities: JsonModel.mapListOf(json['activities']),
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
    if (assignedTo != null) 'assigned_to': assignedTo,
    if (leadStatus != null) 'lead_status': leadStatus,
    if (remarks != null) 'remarks': remarks,
    if (createdBy != null) 'created_by': createdBy,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
    'activities': activities,
  };
}
