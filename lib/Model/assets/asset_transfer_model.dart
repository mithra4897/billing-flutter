import '../../screen.dart';

class AssetTransferModel implements JsonModel {
  const AssetTransferModel({
    this.id,
    this.companyId,
    this.transferNo,
    this.transferDate,
    this.transferReason,
    this.fromBranchId,
    this.toBranchId,
    this.fromLocationId,
    this.toLocationId,
    this.fromDepartmentName,
    this.toDepartmentName,
    this.fromEmployeeName,
    this.toEmployeeName,
    this.transferStatus,
    this.remarks,
    this.voucherId,
    this.approvedBy,
    this.approvedAt,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final int? companyId;
  final String? transferNo;
  final String? transferDate;
  final String? transferReason;
  final int? fromBranchId;
  final int? toBranchId;
  final int? fromLocationId;
  final int? toLocationId;
  final String? fromDepartmentName;
  final String? toDepartmentName;
  final String? fromEmployeeName;
  final String? toEmployeeName;
  final String? transferStatus;
  final String? remarks;
  final int? voucherId;
  final int? approvedBy;
  final String? approvedAt;
  final int? createdBy;
  final int? updatedBy;
  final String? createdAt;
  final String? updatedAt;

  factory AssetTransferModel.fromJson(Map<String, dynamic> json) {
    return AssetTransferModel(
      id: ModelValue.nullableInt(json['id']),
      companyId: ModelValue.nullableInt(json['company_id']),
      transferNo: json['transfer_no']?.toString(),
      transferDate: json['transfer_date']?.toString(),
      transferReason: json['transfer_reason']?.toString(),
      fromBranchId: ModelValue.nullableInt(json['from_branch_id']),
      toBranchId: ModelValue.nullableInt(json['to_branch_id']),
      fromLocationId: ModelValue.nullableInt(json['from_location_id']),
      toLocationId: ModelValue.nullableInt(json['to_location_id']),
      fromDepartmentName: json['from_department_name']?.toString(),
      toDepartmentName: json['to_department_name']?.toString(),
      fromEmployeeName: json['from_employee_name']?.toString(),
      toEmployeeName: json['to_employee_name']?.toString(),
      transferStatus: json['transfer_status']?.toString(),
      remarks: json['remarks']?.toString(),
      voucherId: ModelValue.nullableInt(json['voucher_id']),
      approvedBy: ModelValue.nullableInt(json['approved_by']),
      approvedAt: json['approved_at']?.toString(),
      createdBy: ModelValue.nullableInt(json['created_by']),
      updatedBy: ModelValue.nullableInt(json['updated_by']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (companyId != null) 'company_id': companyId,
    if (transferNo != null) 'transfer_no': transferNo,
    if (transferDate != null) 'transfer_date': transferDate,
    if (transferReason != null) 'transfer_reason': transferReason,
    if (fromBranchId != null) 'from_branch_id': fromBranchId,
    if (toBranchId != null) 'to_branch_id': toBranchId,
    if (fromLocationId != null) 'from_location_id': fromLocationId,
    if (toLocationId != null) 'to_location_id': toLocationId,
    if (fromDepartmentName != null) 'from_department_name': fromDepartmentName,
    if (toDepartmentName != null) 'to_department_name': toDepartmentName,
    if (fromEmployeeName != null) 'from_employee_name': fromEmployeeName,
    if (toEmployeeName != null) 'to_employee_name': toEmployeeName,
    if (transferStatus != null) 'transfer_status': transferStatus,
    if (remarks != null) 'remarks': remarks,
    if (voucherId != null) 'voucher_id': voucherId,
    if (approvedBy != null) 'approved_by': approvedBy,
    if (approvedAt != null) 'approved_at': approvedAt,
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
