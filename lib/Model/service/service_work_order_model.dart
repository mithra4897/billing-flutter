import '../../screen.dart';

class ServiceWorkOrderModel extends JsonModel {
  const ServiceWorkOrderModel({
    super.id,
    this.companyId,
    this.branchId,
    this.locationId,
    this.financialYearId,
    this.documentSeriesId,
    this.workOrderNo,
    this.workOrderDate,
    this.serviceTicketId,
    this.customerPartyId,
    this.assetId,
    this.itemId,
    this.serialId,
    this.serialNo,
    this.workOrderType,
    this.executionMode,
    this.technicianUserId,
    this.vendorPartyId,
    this.workOrderStatus,
    this.diagnosisNotes,
    this.actionTaken,
    this.resolutionSummary,
    this.customerSiteAddress,
    this.checkInDatetime,
    this.checkOutDatetime,
    this.laborCost,
    this.spareCost,
    this.externalServiceCost,
    this.travelCost,
    this.otherCost,
    this.totalCost,
    this.billableAmount,
    this.voucherId,
    this.remarks,
    this.completedBy,
    this.completedAt,
    this.closedBy,
    this.closedAt,
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
  final String? workOrderNo;
  final String? workOrderDate;
  final int? serviceTicketId;
  final int? customerPartyId;
  final int? assetId;
  final int? itemId;
  final int? serialId;
  final String? serialNo;
  final String? workOrderType;
  final String? executionMode;
  final int? technicianUserId;
  final int? vendorPartyId;
  final String? workOrderStatus;
  final String? diagnosisNotes;
  final String? actionTaken;
  final String? resolutionSummary;
  final String? customerSiteAddress;
  final String? checkInDatetime;
  final String? checkOutDatetime;
  final double? laborCost;
  final double? spareCost;
  final double? externalServiceCost;
  final double? travelCost;
  final double? otherCost;
  final double? totalCost;
  final double? billableAmount;
  final int? voucherId;
  final String? remarks;
  final int? completedBy;
  final String? completedAt;
  final int? closedBy;
  final String? closedAt;
  final int? createdBy;
  final int? updatedBy;
  final String? createdAt;
  final String? updatedAt;

  factory ServiceWorkOrderModel.fromJson(Map<String, dynamic> json) {
    return ServiceWorkOrderModel(
      id: JsonModel.nullableInt(json['id']),
      companyId: JsonModel.nullableInt(json['company_id']),
      branchId: JsonModel.nullableInt(json['branch_id']),
      locationId: JsonModel.nullableInt(json['location_id']),
      financialYearId: JsonModel.nullableInt(json['financial_year_id']),
      documentSeriesId: JsonModel.nullableInt(json['document_series_id']),
      workOrderNo: json['work_order_no']?.toString(),
      workOrderDate: json['work_order_date']?.toString(),
      serviceTicketId: JsonModel.nullableInt(json['service_ticket_id']),
      customerPartyId: JsonModel.nullableInt(json['customer_party_id']),
      assetId: JsonModel.nullableInt(json['asset_id']),
      itemId: JsonModel.nullableInt(json['item_id']),
      serialId: JsonModel.nullableInt(json['serial_id']),
      serialNo: json['serial_no']?.toString(),
      workOrderType: json['work_order_type']?.toString(),
      executionMode: json['execution_mode']?.toString(),
      technicianUserId: JsonModel.nullableInt(json['technician_user_id']),
      vendorPartyId: JsonModel.nullableInt(json['vendor_party_id']),
      workOrderStatus: json['work_order_status']?.toString(),
      diagnosisNotes: json['diagnosis_notes']?.toString(),
      actionTaken: json['action_taken']?.toString(),
      resolutionSummary: json['resolution_summary']?.toString(),
      customerSiteAddress: json['customer_site_address']?.toString(),
      checkInDatetime: json['check_in_datetime']?.toString(),
      checkOutDatetime: json['check_out_datetime']?.toString(),
      laborCost: JsonModel.nullableDouble(json['labor_cost']),
      spareCost: JsonModel.nullableDouble(json['spare_cost']),
      externalServiceCost: JsonModel.nullableDouble(
        json['external_service_cost'],
      ),
      travelCost: JsonModel.nullableDouble(json['travel_cost']),
      otherCost: JsonModel.nullableDouble(json['other_cost']),
      totalCost: JsonModel.nullableDouble(json['total_cost']),
      billableAmount: JsonModel.nullableDouble(json['billable_amount']),
      voucherId: JsonModel.nullableInt(json['voucher_id']),
      remarks: json['remarks']?.toString(),
      completedBy: JsonModel.nullableInt(json['completed_by']),
      completedAt: json['completed_at']?.toString(),
      closedBy: JsonModel.nullableInt(json['closed_by']),
      closedAt: json['closed_at']?.toString(),
      createdBy: JsonModel.nullableInt(json['created_by']),
      updatedBy: JsonModel.nullableInt(json['updated_by']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
  @override
  String toString() => JsonModel.combineValues([
    workOrderNo,
    serialNo,
    workOrderDate,
  ], defaultValue: 'Service Work Order');


  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (companyId != null) 'company_id': companyId,
    if (branchId != null) 'branch_id': branchId,
    if (locationId != null) 'location_id': locationId,
    if (financialYearId != null) 'financial_year_id': financialYearId,
    if (documentSeriesId != null) 'document_series_id': documentSeriesId,
    if (workOrderNo != null) 'work_order_no': workOrderNo,
    if (workOrderDate != null) 'work_order_date': workOrderDate,
    if (serviceTicketId != null) 'service_ticket_id': serviceTicketId,
    if (customerPartyId != null) 'customer_party_id': customerPartyId,
    if (assetId != null) 'asset_id': assetId,
    if (itemId != null) 'item_id': itemId,
    if (serialId != null) 'serial_id': serialId,
    if (serialNo != null) 'serial_no': serialNo,
    if (workOrderType != null) 'work_order_type': workOrderType,
    if (executionMode != null) 'execution_mode': executionMode,
    if (technicianUserId != null) 'technician_user_id': technicianUserId,
    if (vendorPartyId != null) 'vendor_party_id': vendorPartyId,
    if (workOrderStatus != null) 'work_order_status': workOrderStatus,
    if (diagnosisNotes != null) 'diagnosis_notes': diagnosisNotes,
    if (actionTaken != null) 'action_taken': actionTaken,
    if (resolutionSummary != null) 'resolution_summary': resolutionSummary,
    if (customerSiteAddress != null)
      'customer_site_address': customerSiteAddress,
    if (checkInDatetime != null) 'check_in_datetime': checkInDatetime,
    if (checkOutDatetime != null) 'check_out_datetime': checkOutDatetime,
    if (laborCost != null) 'labor_cost': laborCost,
    if (spareCost != null) 'spare_cost': spareCost,
    if (externalServiceCost != null)
      'external_service_cost': externalServiceCost,
    if (travelCost != null) 'travel_cost': travelCost,
    if (otherCost != null) 'other_cost': otherCost,
    if (totalCost != null) 'total_cost': totalCost,
    if (billableAmount != null) 'billable_amount': billableAmount,
    if (voucherId != null) 'voucher_id': voucherId,
    if (remarks != null) 'remarks': remarks,
    if (completedBy != null) 'completed_by': completedBy,
    if (completedAt != null) 'completed_at': completedAt,
    if (closedBy != null) 'closed_by': closedBy,
    if (closedAt != null) 'closed_at': closedAt,
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
