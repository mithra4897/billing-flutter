import '../../screen.dart';

class ServiceTicketModel extends JsonModel {
  const ServiceTicketModel({
    super.id,
    this.companyId,
    this.branchId,
    this.locationId,
    this.financialYearId,
    this.documentSeriesId,
    this.ticketNo,
    this.ticketDate,
    this.customerPartyId,
    this.contactPersonName,
    this.contactMobile,
    this.contactEmail,
    this.serviceContractId,
    this.serviceContractAssetId,
    this.assetId,
    this.itemId,
    this.serialId,
    this.serialNo,
    this.ticketType,
    this.priorityLevel,
    this.issueTitle,
    this.issueDescription,
    this.ticketSource,
    this.serviceMode,
    this.coverageType,
    this.targetResponseDatetime,
    this.targetResolutionDatetime,
    this.ticketStatus,
    this.assignedToUserId,
    this.customerSiteAddress,
    this.closedBy,
    this.closedAt,
    this.notes,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  });
  final int? companyId;
  final int? branchId;
  final int? locationId;
  final int? financialYearId;
  final int? documentSeriesId;
  final String? ticketNo;
  final String? ticketDate;
  final int? customerPartyId;
  final String? contactPersonName;
  final String? contactMobile;
  final String? contactEmail;
  final int? serviceContractId;
  final int? serviceContractAssetId;
  final int? assetId;
  final int? itemId;
  final int? serialId;
  final String? serialNo;
  final String? ticketType;
  final String? priorityLevel;
  final String? issueTitle;
  final String? issueDescription;
  final String? ticketSource;
  final String? serviceMode;
  final String? coverageType;
  final String? targetResponseDatetime;
  final String? targetResolutionDatetime;
  final String? ticketStatus;
  final int? assignedToUserId;
  final String? customerSiteAddress;
  final int? closedBy;
  final String? closedAt;
  final String? notes;
  final int? createdBy;
  final int? updatedBy;
  final String? createdAt;
  final String? updatedAt;

  factory ServiceTicketModel.fromJson(Map<String, dynamic> json) {
    return ServiceTicketModel(
      id: JsonModel.nullableInt(json['id']),
      companyId: JsonModel.nullableInt(json['company_id']),
      branchId: JsonModel.nullableInt(json['branch_id']),
      locationId: JsonModel.nullableInt(json['location_id']),
      financialYearId: JsonModel.nullableInt(json['financial_year_id']),
      documentSeriesId: JsonModel.nullableInt(json['document_series_id']),
      ticketNo: json['ticket_no']?.toString(),
      ticketDate: json['ticket_date']?.toString(),
      customerPartyId: JsonModel.nullableInt(json['customer_party_id']),
      contactPersonName: json['contact_person_name']?.toString(),
      contactMobile: json['contact_mobile']?.toString(),
      contactEmail: json['contact_email']?.toString(),
      serviceContractId: JsonModel.nullableInt(json['service_contract_id']),
      serviceContractAssetId: JsonModel.nullableInt(
        json['service_contract_asset_id'],
      ),
      assetId: JsonModel.nullableInt(json['asset_id']),
      itemId: JsonModel.nullableInt(json['item_id']),
      serialId: JsonModel.nullableInt(json['serial_id']),
      serialNo: json['serial_no']?.toString(),
      ticketType: json['ticket_type']?.toString(),
      priorityLevel: json['priority_level']?.toString(),
      issueTitle: json['issue_title']?.toString(),
      issueDescription: json['issue_description']?.toString(),
      ticketSource: json['ticket_source']?.toString(),
      serviceMode: json['service_mode']?.toString(),
      coverageType: json['coverage_type']?.toString(),
      targetResponseDatetime: json['target_response_datetime']?.toString(),
      targetResolutionDatetime: json['target_resolution_datetime']?.toString(),
      ticketStatus: json['ticket_status']?.toString(),
      assignedToUserId: JsonModel.nullableInt(json['assigned_to_user_id']),
      customerSiteAddress: json['customer_site_address']?.toString(),
      closedBy: JsonModel.nullableInt(json['closed_by']),
      closedAt: json['closed_at']?.toString(),
      notes: json['notes']?.toString(),
      createdBy: JsonModel.nullableInt(json['created_by']),
      updatedBy: JsonModel.nullableInt(json['updated_by']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
  @override
  String toString() => JsonModel.combineValues([
    ticketNo,
    issueTitle,
    contactPersonName,
    serialNo,
  ], defaultValue: 'Service Ticket');

  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (companyId != null) 'company_id': companyId,
    if (branchId != null) 'branch_id': branchId,
    if (locationId != null) 'location_id': locationId,
    if (financialYearId != null) 'financial_year_id': financialYearId,
    if (documentSeriesId != null) 'document_series_id': documentSeriesId,
    if (ticketNo != null) 'ticket_no': ticketNo,
    if (ticketDate != null) 'ticket_date': ticketDate,
    if (customerPartyId != null) 'customer_party_id': customerPartyId,
    if (contactPersonName != null) 'contact_person_name': contactPersonName,
    if (contactMobile != null) 'contact_mobile': contactMobile,
    if (contactEmail != null) 'contact_email': contactEmail,
    if (serviceContractId != null) 'service_contract_id': serviceContractId,
    if (serviceContractAssetId != null)
      'service_contract_asset_id': serviceContractAssetId,
    if (assetId != null) 'asset_id': assetId,
    if (itemId != null) 'item_id': itemId,
    if (serialId != null) 'serial_id': serialId,
    if (serialNo != null) 'serial_no': serialNo,
    if (ticketType != null) 'ticket_type': ticketType,
    if (priorityLevel != null) 'priority_level': priorityLevel,
    if (issueTitle != null) 'issue_title': issueTitle,
    if (issueDescription != null) 'issue_description': issueDescription,
    if (ticketSource != null) 'ticket_source': ticketSource,
    if (serviceMode != null) 'service_mode': serviceMode,
    if (coverageType != null) 'coverage_type': coverageType,
    if (targetResponseDatetime != null)
      'target_response_datetime': targetResponseDatetime,
    if (targetResolutionDatetime != null)
      'target_resolution_datetime': targetResolutionDatetime,
    if (ticketStatus != null) 'ticket_status': ticketStatus,
    if (assignedToUserId != null) 'assigned_to_user_id': assignedToUserId,
    if (customerSiteAddress != null)
      'customer_site_address': customerSiteAddress,
    if (closedBy != null) 'closed_by': closedBy,
    if (closedAt != null) 'closed_at': closedAt,
    if (notes != null) 'notes': notes,
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
