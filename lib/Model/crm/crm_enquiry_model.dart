import '../../screen.dart';

class CrmEnquiryModel implements JsonModel {
  const CrmEnquiryModel({
    this.id,
    this.companyId,
    this.enquiryNo,
    this.enquiryDate,
    this.leadId,
    this.customerPartyId,
    this.stageId,
    this.assignedTo,
    this.enquiryStatus,
    this.remarks,
    this.opportunityName,
    this.expectedValue,
    this.probabilityPercent,
    this.expectedCloseDate,
    this.status,
    this.createdAt,
    this.updatedAt,
    Map<String, dynamic>? raw,
  }) : _raw = raw;

  final int? id;
  final int? companyId;
  final String? enquiryNo;
  final String? enquiryDate;
  final int? leadId;
  final int? customerPartyId;
  final int? stageId;
  final int? assignedTo;
  final String? enquiryStatus;
  final String? remarks;
  final String? opportunityName;
  final double? expectedValue;
  final double? probabilityPercent;
  final String? expectedCloseDate;
  final String? status;
  final String? createdAt;
  final String? updatedAt;

  factory CrmEnquiryModel.fromJson(Map<String, dynamic> json) {
    return CrmEnquiryModel(
      id: ModelValue.nullableInt(json['id']),
      companyId: ModelValue.nullableInt(json['company_id']),
      enquiryNo: json['enquiry_no']?.toString(),
      enquiryDate: json['enquiry_date']?.toString(),
      leadId: ModelValue.nullableInt(json['lead_id']),
      customerPartyId: ModelValue.nullableInt(json['customer_party_id']),
      stageId: ModelValue.nullableInt(json['stage_id']),
      assignedTo: ModelValue.nullableInt(json['assigned_to']),
      enquiryStatus: json['enquiry_status']?.toString(),
      remarks: json['remarks']?.toString(),
      opportunityName: json['opportunity_name']?.toString(),
      expectedValue: ModelValue.nullableDouble(json['expected_value']),
      probabilityPercent: ModelValue.nullableDouble(
        json['probability_percent'],
      ),
      expectedCloseDate: json['expected_close_date']?.toString(),
      status: json['status']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (companyId != null) 'company_id': companyId,
    if (enquiryNo != null) 'enquiry_no': enquiryNo,
    if (enquiryDate != null) 'enquiry_date': enquiryDate,
    if (leadId != null) 'lead_id': leadId,
    if (customerPartyId != null) 'customer_party_id': customerPartyId,
    if (stageId != null) 'stage_id': stageId,
    if (assignedTo != null) 'assigned_to': assignedTo,
    if (enquiryStatus != null) 'enquiry_status': enquiryStatus,
    if (remarks != null) 'remarks': remarks,
    if (opportunityName != null) 'opportunity_name': opportunityName,
    if (expectedValue != null) 'expected_value': expectedValue,
    if (probabilityPercent != null) 'probability_percent': probabilityPercent,
    if (expectedCloseDate != null) 'expected_close_date': expectedCloseDate,
    if (status != null) 'status': status,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
