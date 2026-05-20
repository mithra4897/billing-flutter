import '../../screen.dart';

class UserWarehouseAccessModel extends JsonModel {
  const UserWarehouseAccessModel({
    super.id,
    this.userId,
    this.warehouseId,
    this.isDefault,
    this.canViewStock,
    this.canStockIn,
    this.canStockOut,
    this.canTransfer,
    this.canAdjust,
    this.isActive,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  });
  final int? userId;
  final int? warehouseId;
  final bool? isDefault;
  final bool? canViewStock;
  final bool? canStockIn;
  final bool? canStockOut;
  final bool? canTransfer;
  final bool? canAdjust;
  final bool? isActive;
  final int? createdBy;
  final int? updatedBy;
  final String? createdAt;
  final String? updatedAt;

  factory UserWarehouseAccessModel.fromJson(Map<String, dynamic> json) {
    return UserWarehouseAccessModel(
      id: JsonModel.nullableInt(json['id']),
      userId: JsonModel.nullableInt(json['user_id']),
      warehouseId: JsonModel.nullableInt(json['warehouse_id']),
      isDefault: json['is_default'] == null
          ? null
          : JsonModel.boolOf(json['is_default']),
      canViewStock: json['can_view_stock'] == null
          ? null
          : JsonModel.boolOf(json['can_view_stock']),
      canStockIn: json['can_stock_in'] == null
          ? null
          : JsonModel.boolOf(json['can_stock_in']),
      canStockOut: json['can_stock_out'] == null
          ? null
          : JsonModel.boolOf(json['can_stock_out']),
      canTransfer: json['can_transfer'] == null
          ? null
          : JsonModel.boolOf(json['can_transfer']),
      canAdjust: json['can_adjust'] == null
          ? null
          : JsonModel.boolOf(json['can_adjust']),
      isActive: json['is_active'] == null
          ? null
          : JsonModel.boolOf(json['is_active']),
      createdBy: JsonModel.nullableInt(json['created_by']),
      updatedBy: JsonModel.nullableInt(json['updated_by']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
  @override
  String toString() => 'User Warehouse Access';


  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (userId != null) 'user_id': userId,
    if (warehouseId != null) 'warehouse_id': warehouseId,
    if (isDefault != null) 'is_default': isDefault,
    if (canViewStock != null) 'can_view_stock': canViewStock,
    if (canStockIn != null) 'can_stock_in': canStockIn,
    if (canStockOut != null) 'can_stock_out': canStockOut,
    if (canTransfer != null) 'can_transfer': canTransfer,
    if (canAdjust != null) 'can_adjust': canAdjust,
    if (isActive != null) 'is_active': isActive,
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
