import '../../screen.dart';

class BomOperationModel implements JsonModel {
  const BomOperationModel({
    this.id,
    this.bomId,
    this.operationNo,
    this.operationName,
    this.workCenter,
    this.setupTimeMinutes,
    this.runTimeMinutes,
    this.laborCost,
    this.machineCost,
    this.overheadCost,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final int? bomId;
  final String? operationNo;
  final String? operationName;
  final String? workCenter;
  final double? setupTimeMinutes;
  final double? runTimeMinutes;
  final double? laborCost;
  final double? machineCost;
  final double? overheadCost;
  final String? notes;
  final String? createdAt;
  final String? updatedAt;

  factory BomOperationModel.fromJson(Map<String, dynamic> json) {
    return BomOperationModel(
      id: ModelValue.nullableInt(json['id']),
      bomId: ModelValue.nullableInt(json['bom_id']),
      operationNo: json['operation_no']?.toString(),
      operationName: json['operation_name']?.toString(),
      workCenter: json['work_center']?.toString(),
      setupTimeMinutes: ModelValue.nullableDouble(json['setup_time_minutes']),
      runTimeMinutes: ModelValue.nullableDouble(json['run_time_minutes']),
      laborCost: ModelValue.nullableDouble(json['labor_cost']),
      machineCost: ModelValue.nullableDouble(json['machine_cost']),
      overheadCost: ModelValue.nullableDouble(json['overhead_cost']),
      notes: json['notes']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (bomId != null) 'bom_id': bomId,
    if (operationNo != null) 'operation_no': operationNo,
    if (operationName != null) 'operation_name': operationName,
    if (workCenter != null) 'work_center': workCenter,
    if (setupTimeMinutes != null) 'setup_time_minutes': setupTimeMinutes,
    if (runTimeMinutes != null) 'run_time_minutes': runTimeMinutes,
    if (laborCost != null) 'labor_cost': laborCost,
    if (machineCost != null) 'machine_cost': machineCost,
    if (overheadCost != null) 'overhead_cost': overheadCost,
    if (notes != null) 'notes': notes,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
