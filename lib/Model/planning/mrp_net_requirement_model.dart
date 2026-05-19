import '../../screen.dart';

class MrpNetRequirementModel extends JsonModel {
  const MrpNetRequirementModel({
    super.id,
    this.mrpRunId,
    this.itemId,
    this.warehouseId,
    this.grossDemandQty,
    this.availableSupplyQty,
    this.safetyStockQty,
    this.netRequiredQty,
    this.shortageQty,
    this.excessQty,
    this.reorderTriggered,
    this.recommendedAction,
    this.recommendedQty,
    this.recommendedDate,
    this.leadTimeDays,
    this.planningMethod,
    this.procurementType,
    this.remarks,
    this.createdAt,
    this.updatedAt,
  });
  final int? mrpRunId;
  final int? itemId;
  final int? warehouseId;
  final double? grossDemandQty;
  final double? availableSupplyQty;
  final double? safetyStockQty;
  final double? netRequiredQty;
  final double? shortageQty;
  final double? excessQty;
  final bool? reorderTriggered;
  final String? recommendedAction;
  final double? recommendedQty;
  final String? recommendedDate;
  final int? leadTimeDays;
  final String? planningMethod;
  final String? procurementType;
  final String? remarks;
  final String? createdAt;
  final String? updatedAt;

  factory MrpNetRequirementModel.fromJson(Map<String, dynamic> json) {
    return MrpNetRequirementModel(
      id: JsonModel.nullableInt(json['id']),
      mrpRunId: JsonModel.nullableInt(json['mrp_run_id']),
      itemId: JsonModel.nullableInt(json['item_id']),
      warehouseId: JsonModel.nullableInt(json['warehouse_id']),
      grossDemandQty: JsonModel.nullableDouble(json['gross_demand_qty']),
      availableSupplyQty: JsonModel.nullableDouble(
        json['available_supply_qty'],
      ),
      safetyStockQty: JsonModel.nullableDouble(json['safety_stock_qty']),
      netRequiredQty: JsonModel.nullableDouble(json['net_required_qty']),
      shortageQty: JsonModel.nullableDouble(json['shortage_qty']),
      excessQty: JsonModel.nullableDouble(json['excess_qty']),
      reorderTriggered: json['reorder_triggered'] == null
          ? null
          : JsonModel.boolOf(json['reorder_triggered']),
      recommendedAction: json['recommended_action']?.toString(),
      recommendedQty: JsonModel.nullableDouble(json['recommended_qty']),
      recommendedDate: json['recommended_date']?.toString(),
      leadTimeDays: JsonModel.nullableInt(json['lead_time_days']),
      planningMethod: json['planning_method']?.toString(),
      procurementType: json['procurement_type']?.toString(),
      remarks: json['remarks']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
  @override
  String toString() => 'Mrp Net Requirement';


  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (mrpRunId != null) 'mrp_run_id': mrpRunId,
    if (itemId != null) 'item_id': itemId,
    if (warehouseId != null) 'warehouse_id': warehouseId,
    if (grossDemandQty != null) 'gross_demand_qty': grossDemandQty,
    if (availableSupplyQty != null) 'available_supply_qty': availableSupplyQty,
    if (safetyStockQty != null) 'safety_stock_qty': safetyStockQty,
    if (netRequiredQty != null) 'net_required_qty': netRequiredQty,
    if (shortageQty != null) 'shortage_qty': shortageQty,
    if (excessQty != null) 'excess_qty': excessQty,
    if (reorderTriggered != null) 'reorder_triggered': reorderTriggered,
    if (recommendedAction != null) 'recommended_action': recommendedAction,
    if (recommendedQty != null) 'recommended_qty': recommendedQty,
    if (recommendedDate != null) 'recommended_date': recommendedDate,
    if (leadTimeDays != null) 'lead_time_days': leadTimeDays,
    if (planningMethod != null) 'planning_method': planningMethod,
    if (procurementType != null) 'procurement_type': procurementType,
    if (remarks != null) 'remarks': remarks,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
