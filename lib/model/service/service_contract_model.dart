import '../../screen.dart';

class ServiceContractModel extends JsonModel {
  const ServiceContractModel({
    super.id,
    this.companyId,
    this.contractNo,
    this.contractDate,
    this.customerPartyId,
    this.contractType,
    this.contractStartDate,
    this.contractEndDate,
    this.coverageScope,
    this.visitFrequency,
    this.responseTimeHours,
    this.resolutionTimeHours,
    this.contractValue,
    this.taxAmount,
    this.totalValue,
    this.salesInvoiceId,
    this.contractStatus,
    this.notes,
    this.approvedBy,
    this.approvedAt,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  });
  final int? companyId;
  final String? contractNo;
  final String? contractDate;
  final int? customerPartyId;
  final String? contractType;
  final String? contractStartDate;
  final String? contractEndDate;
  final String? coverageScope;
  final String? visitFrequency;
  final double? responseTimeHours;
  final double? resolutionTimeHours;
  final double? contractValue;
  final double? taxAmount;
  final double? totalValue;
  final int? salesInvoiceId;
  final String? contractStatus;
  final String? notes;
  final int? approvedBy;
  final String? approvedAt;
  final int? createdBy;
  final int? updatedBy;
  final String? createdAt;
  final String? updatedAt;

  factory ServiceContractModel.fromJson(Map<String, dynamic> json) {
    return ServiceContractModel(
      id: JsonModel.nullableInt(json['id']),
      companyId: JsonModel.nullableInt(json['company_id']),
      contractNo: json['contract_no']?.toString(),
      contractDate: json['contract_date']?.toString(),
      customerPartyId: JsonModel.nullableInt(json['customer_party_id']),
      contractType: json['contract_type']?.toString(),
      contractStartDate: json['contract_start_date']?.toString(),
      contractEndDate: json['contract_end_date']?.toString(),
      coverageScope: json['coverage_scope']?.toString(),
      visitFrequency: json['visit_frequency']?.toString(),
      responseTimeHours: JsonModel.nullableDouble(json['response_time_hours']),
      resolutionTimeHours: JsonModel.nullableDouble(
        json['resolution_time_hours'],
      ),
      contractValue: JsonModel.nullableDouble(json['contract_value']),
      taxAmount: JsonModel.nullableDouble(json['tax_amount']),
      totalValue: JsonModel.nullableDouble(json['total_value']),
      salesInvoiceId: JsonModel.nullableInt(json['sales_invoice_id']),
      contractStatus: json['contract_status']?.toString(),
      notes: json['notes']?.toString(),
      approvedBy: JsonModel.nullableInt(json['approved_by']),
      approvedAt: json['approved_at']?.toString(),
      createdBy: JsonModel.nullableInt(json['created_by']),
      updatedBy: JsonModel.nullableInt(json['updated_by']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
  @override
  String toString() => JsonModel.combineValues([
    contractNo,
    contractDate,
    contractStartDate,
  ], defaultValue: 'Service Contract');


  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (companyId != null) 'company_id': companyId,
    if (contractNo != null) 'contract_no': contractNo,
    if (contractDate != null) 'contract_date': contractDate,
    if (customerPartyId != null) 'customer_party_id': customerPartyId,
    if (contractType != null) 'contract_type': contractType,
    if (contractStartDate != null) 'contract_start_date': contractStartDate,
    if (contractEndDate != null) 'contract_end_date': contractEndDate,
    if (coverageScope != null) 'coverage_scope': coverageScope,
    if (visitFrequency != null) 'visit_frequency': visitFrequency,
    if (responseTimeHours != null) 'response_time_hours': responseTimeHours,
    if (resolutionTimeHours != null)
      'resolution_time_hours': resolutionTimeHours,
    if (contractValue != null) 'contract_value': contractValue,
    if (taxAmount != null) 'tax_amount': taxAmount,
    if (totalValue != null) 'total_value': totalValue,
    if (salesInvoiceId != null) 'sales_invoice_id': salesInvoiceId,
    if (contractStatus != null) 'contract_status': contractStatus,
    if (notes != null) 'notes': notes,
    if (approvedBy != null) 'approved_by': approvedBy,
    if (approvedAt != null) 'approved_at': approvedAt,
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
