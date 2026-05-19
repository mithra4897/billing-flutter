import '../../screen.dart';

class BomOperationModel extends JsonModel {
  const BomOperationModel({
    super.id,
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
      id: JsonModel.nullableInt(json['id']),
      bomId: JsonModel.nullableInt(json['bom_id']),
      operationNo: json['operation_no']?.toString(),
      operationName: json['operation_name']?.toString(),
      workCenter: json['work_center']?.toString(),
      setupTimeMinutes: JsonModel.nullableDouble(json['setup_time_minutes']),
      runTimeMinutes: JsonModel.nullableDouble(json['run_time_minutes']),
      laborCost: JsonModel.nullableDouble(json['labor_cost']),
      machineCost: JsonModel.nullableDouble(json['machine_cost']),
      overheadCost: JsonModel.nullableDouble(json['overhead_cost']),
      notes: json['notes']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
  @override
  String toString() => 'Bom Operation';


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
