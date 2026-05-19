import '../../screen.dart';

class ItemPlanningPolicyModel extends JsonModel {
  const ItemPlanningPolicyModel({
    super.id,
    this.companyId,
    this.branchId,
    this.locationId,
    this.warehouseId,
    this.itemId,
    this.planningMethod,
    this.procurementType,
    this.leadTimeDays,
    this.safetyStockQty,
    this.reorderLevelQty,
    this.reorderQty,
    this.minStockQty,
    this.maxStockQty,
    this.minimumOrderQty,
    this.maxOrderQty,
    this.orderMultipleQty,
    this.preferredSupplierPartyId,
    this.preferredBomId,
    this.preferredWarehouseId,
    this.planningFenceDays,
    this.isMrpEnabled,
    this.isReorderEnabled,
    this.isActive,
    this.remarks,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  });
  final int? companyId;
  final int? branchId;
  final int? locationId;
  final int? warehouseId;
  final int? itemId;
  final String? planningMethod;
  final String? procurementType;
  final int? leadTimeDays;
  final double? safetyStockQty;
  final double? reorderLevelQty;
  final double? reorderQty;
  final double? minStockQty;
  final double? maxStockQty;
  final double? minimumOrderQty;
  final double? maxOrderQty;
  final double? orderMultipleQty;
  final int? preferredSupplierPartyId;
  final int? preferredBomId;
  final int? preferredWarehouseId;
  final int? planningFenceDays;
  final bool? isMrpEnabled;
  final bool? isReorderEnabled;
  final bool? isActive;
  final String? remarks;
  final int? createdBy;
  final int? updatedBy;
  final String? createdAt;
  final String? updatedAt;

  factory ItemPlanningPolicyModel.fromJson(Map<String, dynamic> json) {
    return ItemPlanningPolicyModel(
      id: JsonModel.nullableInt(json['id']),
      companyId: JsonModel.nullableInt(json['company_id']),
      branchId: JsonModel.nullableInt(json['branch_id']),
      locationId: JsonModel.nullableInt(json['location_id']),
      warehouseId: JsonModel.nullableInt(json['warehouse_id']),
      itemId: JsonModel.nullableInt(json['item_id']),
      planningMethod: json['planning_method']?.toString(),
      procurementType: json['procurement_type']?.toString(),
      leadTimeDays: JsonModel.nullableInt(json['lead_time_days']),
      safetyStockQty: JsonModel.nullableDouble(json['safety_stock_qty']),
      reorderLevelQty: JsonModel.nullableDouble(json['reorder_level_qty']),
      reorderQty: JsonModel.nullableDouble(json['reorder_qty']),
      minStockQty: JsonModel.nullableDouble(json['min_stock_qty']),
      maxStockQty: JsonModel.nullableDouble(json['max_stock_qty']),
      minimumOrderQty: JsonModel.nullableDouble(json['minimum_order_qty']),
      maxOrderQty: JsonModel.nullableDouble(json['max_order_qty']),
      orderMultipleQty: JsonModel.nullableDouble(json['order_multiple_qty']),
      preferredSupplierPartyId: JsonModel.nullableInt(
        json['preferred_supplier_party_id'],
      ),
      preferredBomId: JsonModel.nullableInt(json['preferred_bom_id']),
      preferredWarehouseId: JsonModel.nullableInt(
        json['preferred_warehouse_id'],
      ),
      planningFenceDays: JsonModel.nullableInt(json['planning_fence_days']),
      isMrpEnabled: json['is_mrp_enabled'] == null
          ? null
          : JsonModel.boolOf(json['is_mrp_enabled']),
      isReorderEnabled: json['is_reorder_enabled'] == null
          ? null
          : JsonModel.boolOf(json['is_reorder_enabled']),
      isActive: json['is_active'] == null
          ? null
          : JsonModel.boolOf(json['is_active']),
      remarks: json['remarks']?.toString(),
      createdBy: JsonModel.nullableInt(json['created_by']),
      updatedBy: JsonModel.nullableInt(json['updated_by']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
  @override
  String toString() => JsonModel.combineValues([
    procurementType,
  ], defaultValue: 'Item Planning Policy');


  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (companyId != null) 'company_id': companyId,
    if (branchId != null) 'branch_id': branchId,
    if (locationId != null) 'location_id': locationId,
    if (warehouseId != null) 'warehouse_id': warehouseId,
    if (itemId != null) 'item_id': itemId,
    if (planningMethod != null) 'planning_method': planningMethod,
    if (procurementType != null) 'procurement_type': procurementType,
    if (leadTimeDays != null) 'lead_time_days': leadTimeDays,
    if (safetyStockQty != null) 'safety_stock_qty': safetyStockQty,
    if (reorderLevelQty != null) 'reorder_level_qty': reorderLevelQty,
    if (reorderQty != null) 'reorder_qty': reorderQty,
    if (minStockQty != null) 'min_stock_qty': minStockQty,
    if (maxStockQty != null) 'max_stock_qty': maxStockQty,
    if (minimumOrderQty != null) 'minimum_order_qty': minimumOrderQty,
    if (maxOrderQty != null) 'max_order_qty': maxOrderQty,
    if (orderMultipleQty != null) 'order_multiple_qty': orderMultipleQty,
    if (preferredSupplierPartyId != null)
      'preferred_supplier_party_id': preferredSupplierPartyId,
    if (preferredBomId != null) 'preferred_bom_id': preferredBomId,
    if (preferredWarehouseId != null)
      'preferred_warehouse_id': preferredWarehouseId,
    if (planningFenceDays != null) 'planning_fence_days': planningFenceDays,
    if (isMrpEnabled != null) 'is_mrp_enabled': isMrpEnabled,
    if (isReorderEnabled != null) 'is_reorder_enabled': isReorderEnabled,
    if (isActive != null) 'is_active': isActive,
    if (remarks != null) 'remarks': remarks,
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
