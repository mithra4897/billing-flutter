import '../../screen.dart';

class AssetTransferLineModel extends JsonModel {
  const AssetTransferLineModel({
    super.id,
    this.assetTransferId,
    this.lineNo,
    this.assetId,
    this.fromBranchId,
    this.toBranchId,
    this.fromLocationId,
    this.toLocationId,
    this.fromDepartmentName,
    this.toDepartmentName,
    this.fromEmployeeName,
    this.toEmployeeName,
    this.remarks,
    this.createdAt,
    this.updatedAt,
  });
  final int? assetTransferId;
  final int? lineNo;
  final int? assetId;
  final int? fromBranchId;
  final int? toBranchId;
  final int? fromLocationId;
  final int? toLocationId;
  final String? fromDepartmentName;
  final String? toDepartmentName;
  final String? fromEmployeeName;
  final String? toEmployeeName;
  final String? remarks;
  final String? createdAt;
  final String? updatedAt;

  factory AssetTransferLineModel.fromJson(Map<String, dynamic> json) {
    return AssetTransferLineModel(
      id: JsonModel.nullableInt(json['id']),
      assetTransferId: JsonModel.nullableInt(json['asset_transfer_id']),
      lineNo: JsonModel.nullableInt(json['line_no']),
      assetId: JsonModel.nullableInt(json['asset_id']),
      fromBranchId: JsonModel.nullableInt(json['from_branch_id']),
      toBranchId: JsonModel.nullableInt(json['to_branch_id']),
      fromLocationId: JsonModel.nullableInt(json['from_location_id']),
      toLocationId: JsonModel.nullableInt(json['to_location_id']),
      fromDepartmentName: json['from_department_name']?.toString(),
      toDepartmentName: json['to_department_name']?.toString(),
      fromEmployeeName: json['from_employee_name']?.toString(),
      toEmployeeName: json['to_employee_name']?.toString(),
      remarks: json['remarks']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
  @override
  String toString() => JsonModel.combineValues([
    fromDepartmentName,
    toDepartmentName,
    fromEmployeeName,
  ], defaultValue: 'Asset Transfer Line');


  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (assetTransferId != null) 'asset_transfer_id': assetTransferId,
    if (lineNo != null) 'line_no': lineNo,
    if (assetId != null) 'asset_id': assetId,
    if (fromBranchId != null) 'from_branch_id': fromBranchId,
    if (toBranchId != null) 'to_branch_id': toBranchId,
    if (fromLocationId != null) 'from_location_id': fromLocationId,
    if (toLocationId != null) 'to_location_id': toLocationId,
    if (fromDepartmentName != null) 'from_department_name': fromDepartmentName,
    if (toDepartmentName != null) 'to_department_name': toDepartmentName,
    if (fromEmployeeName != null) 'from_employee_name': fromEmployeeName,
    if (toEmployeeName != null) 'to_employee_name': toEmployeeName,
    if (remarks != null) 'remarks': remarks,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
