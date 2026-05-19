import '../../screen.dart';

class CrmFollowupModel extends JsonModel {
  const CrmFollowupModel({
    super.id,
    this.enquiryId,
    this.followupDate,
    this.notes,
    this.nextFollowup,
    this.assignedTo,
    this.status,
    this.createdAt,
    this.updatedAt,
  });
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
      id: JsonModel.nullableInt(json['id']),
      enquiryId: JsonModel.nullableInt(json['enquiry_id']),
      followupDate: json['followup_date']?.toString(),
      notes: json['notes']?.toString(),
      nextFollowup: json['next_followup']?.toString(),
      assignedTo: JsonModel.nullableInt(json['assigned_to']),
      status: json['status']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
  @override
  String toString() => JsonModel.combineValues([
    followupDate,
  ], defaultValue: 'CRM Followup');


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
