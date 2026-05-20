import '../../screen.dart';

class CrmOpportunityModel extends JsonModel {
  const CrmOpportunityModel({
    super.id,
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
    this.lead,
    this.customer,
    this.stage,
    this.assignedUser,
    this.linesCount,
    this.followupsCount,
    this.productsCount,
    this.lines = const <Map<String, dynamic>>[],
    this.followups = const <Map<String, dynamic>>[],
    this.products = const <Map<String, dynamic>>[],
  });

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
  final Map<String, dynamic>? lead;
  final Map<String, dynamic>? customer;
  final Map<String, dynamic>? stage;
  final Map<String, dynamic>? assignedUser;
  final int? linesCount;
  final int? followupsCount;
  final int? productsCount;
  final List<Map<String, dynamic>> lines;
  final List<Map<String, dynamic>> followups;
  final List<Map<String, dynamic>> products;

  factory CrmOpportunityModel.fromJson(Map<String, dynamic> json) {
    return CrmOpportunityModel(
      id: JsonModel.nullableInt(json['id']),
      companyId: JsonModel.nullableInt(json['company_id']),
      enquiryNo: json['enquiry_no']?.toString(),
      enquiryDate: json['enquiry_date']?.toString(),
      leadId: JsonModel.nullableInt(json['lead_id']),
      customerPartyId: JsonModel.nullableInt(json['customer_party_id']),
      stageId: JsonModel.nullableInt(json['stage_id']),
      assignedTo: JsonModel.nullableInt(json['assigned_to']),
      enquiryStatus: json['enquiry_status']?.toString(),
      remarks: json['remarks']?.toString(),
      opportunityName: json['opportunity_name']?.toString(),
      expectedValue: JsonModel.nullableDouble(json['expected_value']),
      probabilityPercent: JsonModel.nullableDouble(json['probability_percent']),
      expectedCloseDate: json['expected_close_date']?.toString(),
      status: json['status']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      lead: JsonModel.mapOf(json['lead']),
      customer: JsonModel.mapOf(json['customer']),
      stage: JsonModel.mapOf(json['stage']),
      assignedUser: JsonModel.mapOf(
        json['assignedUser'] ?? json['assigned_user'],
      ),
      linesCount: JsonModel.nullableInt(json['lines_count']),
      followupsCount: JsonModel.nullableInt(json['followups_count']),
      productsCount: JsonModel.nullableInt(json['products_count']),
      lines: _mapList(json['lines']),
      followups: _mapList(json['followups']),
      products: _mapList(json['products']),
    );
  }

  @override
  String toString() => JsonModel.combineValues([
    opportunityName,
    customer?['display_name'],
    customer?['party_name'],
  ], defaultValue: 'CRM Opportunity');

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
    if (lead != null) 'lead': lead,
    if (customer != null) 'customer': customer,
    if (stage != null) 'stage': stage,
    if (assignedUser != null) 'assigned_user': assignedUser,
    if (linesCount != null) 'lines_count': linesCount,
    if (followupsCount != null) 'followups_count': followupsCount,
    if (productsCount != null) 'products_count': productsCount,
    'lines': lines,
    'followups': followups,
    'products': products,
  };

  static List<Map<String, dynamic>> _mapList(dynamic value) {
    if (value is! List) {
      return const <Map<String, dynamic>>[];
    }

    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }
}
