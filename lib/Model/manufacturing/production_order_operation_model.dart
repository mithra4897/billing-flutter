import '../../screen.dart';

class ProductionOrderOperationModel extends JsonModel {
  const ProductionOrderOperationModel({
    super.id,
    this.productionOrderId,
    this.bomOperationId,
    this.operationNo,
    this.operationName,
    this.workCenter,
    this.plannedSetupTimeMinutes,
    this.plannedRunTimeMinutes,
    this.actualSetupTimeMinutes,
    this.actualRunTimeMinutes,
    this.laborCost,
    this.machineCost,
    this.overheadCost,
    this.operationStatus,
    this.remarks,
    this.createdAt,
    this.updatedAt,
  });
  final int? productionOrderId;
  final int? bomOperationId;
  final String? operationNo;
  final String? operationName;
  final String? workCenter;
  final double? plannedSetupTimeMinutes;
  final double? plannedRunTimeMinutes;
  final double? actualSetupTimeMinutes;
  final double? actualRunTimeMinutes;
  final double? laborCost;
  final double? machineCost;
  final double? overheadCost;
  final String? operationStatus;
  final String? remarks;
  final String? createdAt;
  final String? updatedAt;

  factory ProductionOrderOperationModel.fromJson(Map<String, dynamic> json) {
    return ProductionOrderOperationModel(
      id: JsonModel.nullableInt(json['id']),
      productionOrderId: JsonModel.nullableInt(json['production_order_id']),
      bomOperationId: JsonModel.nullableInt(json['bom_operation_id']),
      operationNo: json['operation_no']?.toString(),
      operationName: json['operation_name']?.toString(),
      workCenter: json['work_center']?.toString(),
      plannedSetupTimeMinutes: JsonModel.nullableDouble(
        json['planned_setup_time_minutes'],
      ),
      plannedRunTimeMinutes: JsonModel.nullableDouble(
        json['planned_run_time_minutes'],
      ),
      actualSetupTimeMinutes: JsonModel.nullableDouble(
        json['actual_setup_time_minutes'],
      ),
      actualRunTimeMinutes: JsonModel.nullableDouble(
        json['actual_run_time_minutes'],
      ),
      laborCost: JsonModel.nullableDouble(json['labor_cost']),
      machineCost: JsonModel.nullableDouble(json['machine_cost']),
      overheadCost: JsonModel.nullableDouble(json['overhead_cost']),
      operationStatus: json['operation_status']?.toString(),
      remarks: json['remarks']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
  @override
  String toString() => 'Production Order Operation';


  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (productionOrderId != null) 'production_order_id': productionOrderId,
    if (bomOperationId != null) 'bom_operation_id': bomOperationId,
    if (operationNo != null) 'operation_no': operationNo,
    if (operationName != null) 'operation_name': operationName,
    if (workCenter != null) 'work_center': workCenter,
    if (plannedSetupTimeMinutes != null)
      'planned_setup_time_minutes': plannedSetupTimeMinutes,
    if (plannedRunTimeMinutes != null)
      'planned_run_time_minutes': plannedRunTimeMinutes,
    if (actualSetupTimeMinutes != null)
      'actual_setup_time_minutes': actualSetupTimeMinutes,
    if (actualRunTimeMinutes != null)
      'actual_run_time_minutes': actualRunTimeMinutes,
    if (laborCost != null) 'labor_cost': laborCost,
    if (machineCost != null) 'machine_cost': machineCost,
    if (overheadCost != null) 'overhead_cost': overheadCost,
    if (operationStatus != null) 'operation_status': operationStatus,
    if (remarks != null) 'remarks': remarks,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
