import '../../screen.dart';

class PurchaseRequisitionModel extends JsonModel {
  const PurchaseRequisitionModel({
    super.id,
    this.companyId,
    this.branchId,
    this.locationId,
    this.financialYearId,
    this.documentSeriesId,
    this.requisitionNo,
    this.requisitionDate,
    this.requiredDate,
    this.requestedBy,
    this.department,
    this.purpose,
    this.requisitionStatus,
    this.notes,
    this.approvedBy,
    this.approvedAt,
    this.isActive,
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
  final String? requisitionNo;
  final String? requisitionDate;
  final String? requiredDate;
  final int? requestedBy;
  final String? department;
  final String? purpose;
  final String? requisitionStatus;
  final String? notes;
  final int? approvedBy;
  final String? approvedAt;
  final bool? isActive;
  final int? createdBy;
  final int? updatedBy;
  final String? createdAt;
  final String? updatedAt;

  factory PurchaseRequisitionModel.fromJson(Map<String, dynamic> json) {
    return PurchaseRequisitionModel(
      id: ModelValue.nullableInt(json['id']),
      companyId: ModelValue.nullableInt(json['company_id']),
      branchId: ModelValue.nullableInt(json['branch_id']),
      locationId: ModelValue.nullableInt(json['location_id']),
      financialYearId: ModelValue.nullableInt(json['financial_year_id']),
      documentSeriesId: ModelValue.nullableInt(json['document_series_id']),
      requisitionNo: json['requisition_no']?.toString(),
      requisitionDate: json['requisition_date']?.toString(),
      requiredDate: json['required_date']?.toString(),
      requestedBy: ModelValue.nullableInt(json['requested_by']),
      department: json['department']?.toString(),
      purpose: json['purpose']?.toString(),
      requisitionStatus: json['requisition_status']?.toString(),
      notes: json['notes']?.toString(),
      approvedBy: ModelValue.nullableInt(json['approved_by']),
      approvedAt: json['approved_at']?.toString(),
      isActive: json['is_active'] == null
          ? null
          : ModelValue.boolOf(json['is_active']),
      createdBy: ModelValue.nullableInt(json['created_by']),
      updatedBy: ModelValue.nullableInt(json['updated_by']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
  @override
  String toString() => 'Purchase Requisition';


  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (companyId != null) 'company_id': companyId,
    if (branchId != null) 'branch_id': branchId,
    if (locationId != null) 'location_id': locationId,
    if (financialYearId != null) 'financial_year_id': financialYearId,
    if (documentSeriesId != null) 'document_series_id': documentSeriesId,
    if (requisitionNo != null) 'requisition_no': requisitionNo,
    if (requisitionDate != null) 'requisition_date': requisitionDate,
    if (requiredDate != null) 'required_date': requiredDate,
    if (requestedBy != null) 'requested_by': requestedBy,
    if (department != null) 'department': department,
    if (purpose != null) 'purpose': purpose,
    if (requisitionStatus != null) 'requisition_status': requisitionStatus,
    if (notes != null) 'notes': notes,
    if (approvedBy != null) 'approved_by': approvedBy,
    if (approvedAt != null) 'approved_at': approvedAt,
    if (isActive != null) 'is_active': isActive,
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
