import '../../screen.dart';

class AmcContractModel extends JsonModel {
  const AmcContractModel({
    super.id,
    this.companyId,
    this.contractNo,
    this.contractDate,
    this.vendorPartyId,
    this.contractType,
    this.contractStartDate,
    this.contractEndDate,
    this.coverageScope,
    this.visitFrequency,
    this.contractValue,
    this.taxAmount,
    this.totalValue,
    this.responseTimeHours,
    this.resolutionTimeHours,
    this.contractStatus,
    this.remarks,
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
  final int? vendorPartyId;
  final String? contractType;
  final String? contractStartDate;
  final String? contractEndDate;
  final String? coverageScope;
  final String? visitFrequency;
  final double? contractValue;
  final double? taxAmount;
  final double? totalValue;
  final double? responseTimeHours;
  final double? resolutionTimeHours;
  final String? contractStatus;
  final String? remarks;
  final int? approvedBy;
  final String? approvedAt;
  final int? createdBy;
  final int? updatedBy;
  final String? createdAt;
  final String? updatedAt;

  factory AmcContractModel.fromJson(Map<String, dynamic> json) {
    return AmcContractModel(
      id: JsonModel.nullableInt(json['id']),
      companyId: JsonModel.nullableInt(json['company_id']),
      contractNo: json['contract_no']?.toString(),
      contractDate: json['contract_date']?.toString(),
      vendorPartyId: JsonModel.nullableInt(json['vendor_party_id']),
      contractType: json['contract_type']?.toString(),
      contractStartDate: json['contract_start_date']?.toString(),
      contractEndDate: json['contract_end_date']?.toString(),
      coverageScope: json['coverage_scope']?.toString(),
      visitFrequency: json['visit_frequency']?.toString(),
      contractValue: JsonModel.nullableDouble(json['contract_value']),
      taxAmount: JsonModel.nullableDouble(json['tax_amount']),
      totalValue: JsonModel.nullableDouble(json['total_value']),
      responseTimeHours: JsonModel.nullableDouble(json['response_time_hours']),
      resolutionTimeHours: JsonModel.nullableDouble(
        json['resolution_time_hours'],
      ),
      contractStatus: json['contract_status']?.toString(),
      remarks: json['remarks']?.toString(),
      approvedBy: JsonModel.nullableInt(json['approved_by']),
      approvedAt: json['approved_at']?.toString(),
      createdBy: JsonModel.nullableInt(json['created_by']),
      updatedBy: JsonModel.nullableInt(json['updated_by']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
  @override
  String toString() => 'Amc Contract';


  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (companyId != null) 'company_id': companyId,
    if (contractNo != null) 'contract_no': contractNo,
    if (contractDate != null) 'contract_date': contractDate,
    if (vendorPartyId != null) 'vendor_party_id': vendorPartyId,
    if (contractType != null) 'contract_type': contractType,
    if (contractStartDate != null) 'contract_start_date': contractStartDate,
    if (contractEndDate != null) 'contract_end_date': contractEndDate,
    if (coverageScope != null) 'coverage_scope': coverageScope,
    if (visitFrequency != null) 'visit_frequency': visitFrequency,
    if (contractValue != null) 'contract_value': contractValue,
    if (taxAmount != null) 'tax_amount': taxAmount,
    if (totalValue != null) 'total_value': totalValue,
    if (responseTimeHours != null) 'response_time_hours': responseTimeHours,
    if (resolutionTimeHours != null)
      'resolution_time_hours': resolutionTimeHours,
    if (contractStatus != null) 'contract_status': contractStatus,
    if (remarks != null) 'remarks': remarks,
    if (approvedBy != null) 'approved_by': approvedBy,
    if (approvedAt != null) 'approved_at': approvedAt,
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
