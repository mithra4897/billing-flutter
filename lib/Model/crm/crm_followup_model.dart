import '../../screen.dart';

class CrmFollowupModel implements JsonModel {
  const CrmFollowupModel({
    this.id,
    this.enquiryId,
    this.followupDate,
    this.notes,
    this.nextFollowup,
    this.assignedTo,
    this.status,
    this.createdAt,
    this.updatedAt,
    Map<String, dynamic>? raw,
  }) : _raw = raw;

  final int? id;
  final int? enquiryId;
  final String? followupDate;
  final String? notes;
  final String? nextFollowup;
  final int? assignedTo;
  final String? status;
  final String? createdAt;
  final String? updatedAt;

  factory CrmFollowupModel.fromJson(Map<String, dynamic> json) {
    return CrmFollowupModel(
      id: ModelValue.nullableInt(json['id']),
      enquiryId: ModelValue.nullableInt(json['enquiry_id']),
      followupDate: json['followup_date']?.toString(),
      notes: json['notes']?.toString(),
      nextFollowup: json['next_followup']?.toString(),
      assignedTo: ModelValue.nullableInt(json['assigned_to']),
      status: json['status']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (enquiryId != null) 'enquiry_id': enquiryId,
    if (followupDate != null) 'followup_date': followupDate,
    if (notes != null) 'notes': notes,
    if (nextFollowup != null) 'next_followup': nextFollowup,
    if (assignedTo != null) 'assigned_to': assignedTo,
    if (status != null) 'status': status,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
