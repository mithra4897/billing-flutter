import '../../screen.dart';

class CrmFollowupModel extends JsonModel {
  const CrmFollowupModel({
    super.id,
    this.enquiryId,
    this.enquiryNo,
    this.opportunityName,
    this.expectedValue,
    this.customerName,
    this.leadName,
    this.subjectName,
    this.followupDate,
    this.notes,
    this.nextFollowup,
    this.assignedTo,
    this.assignedUser,
    this.priority,
    this.summary,
    this.dateBucket,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  final int? enquiryId;
  final String? enquiryNo;
  final String? opportunityName;
  final double? expectedValue;
  final String? customerName;
  final String? leadName;
  final String? subjectName;
  final String? followupDate;
  final String? notes;
  final String? nextFollowup;
  final int? assignedTo;
  final Map<String, dynamic>? assignedUser;
  final String? priority;
  final String? summary;
  final String? dateBucket;
  final String? status;
  final String? createdAt;
  final String? updatedAt;

  factory CrmFollowupModel.fromJson(Map<String, dynamic> json) {
    return CrmFollowupModel(
      id: JsonModel.nullableInt(json['id']),
      enquiryId: JsonModel.nullableInt(json['enquiry_id']),
      enquiryNo: json['enquiry_no']?.toString(),
      opportunityName: json['opportunity_name']?.toString(),
      expectedValue: JsonModel.nullableDouble(json['expected_value']),
      customerName: json['customer_name']?.toString(),
      leadName: json['lead_name']?.toString(),
      subjectName: json['subject_name']?.toString(),
      followupDate: json['followup_date']?.toString(),
      notes: json['notes']?.toString(),
      nextFollowup: json['next_followup']?.toString(),
      assignedTo: JsonModel.nullableInt(json['assigned_to']),
      assignedUser: json['assigned_user'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['assigned_user'] as Map<String, dynamic>)
          : json['assigned_user'] is Map
          ? Map<String, dynamic>.from(json['assigned_user'] as Map)
          : null,
      priority: json['priority']?.toString(),
      summary: json['summary']?.toString(),
      dateBucket: json['date_bucket']?.toString(),
      status: json['status']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  @override
  String toString() =>
      JsonModel.combineValues([notes], defaultValue: 'CRM Followup');

  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (enquiryId != null) 'enquiry_id': enquiryId,
    if (enquiryNo != null) 'enquiry_no': enquiryNo,
    if (opportunityName != null) 'opportunity_name': opportunityName,
    if (expectedValue != null) 'expected_value': expectedValue,
    if (customerName != null) 'customer_name': customerName,
    if (leadName != null) 'lead_name': leadName,
    if (subjectName != null) 'subject_name': subjectName,
    if (followupDate != null) 'followup_date': followupDate,
    if (notes != null) 'notes': notes,
    if (nextFollowup != null) 'next_followup': nextFollowup,
    if (assignedTo != null) 'assigned_to': assignedTo,
    if (assignedUser != null) 'assigned_user': assignedUser,
    if (priority != null) 'priority': priority,
    if (summary != null) 'summary': summary,
    if (dateBucket != null) 'date_bucket': dateBucket,
    if (status != null) 'status': status,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
