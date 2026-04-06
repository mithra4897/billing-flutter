import '../common/json_model.dart';

class WarehouseModel implements JsonModel {
  const WarehouseModel({
    this.id,
    this.companyId,
    this.code,
    this.name,
    this.branchId,
    this.locationId,
    this.warehouseType,
    this.parentWarehouseId,
    this.allowNegativeStock = false,
    this.isSellableStock = true,
    this.isReservedOnly = false,
    this.isDefault = false,
    this.isActive = true,
    this.remarks,
    this.raw,
  });

  final int? id;
  final int? companyId;
  final String? code;
  final String? name;
  final int? branchId;
  final int? locationId;
  final String? warehouseType;
  final int? parentWarehouseId;
  final bool allowNegativeStock;
  final bool isSellableStock;
  final bool isReservedOnly;
  final bool isDefault;
  final bool isActive;
  final String? remarks;
  final Map<String, dynamic>? raw;

  factory WarehouseModel.fromJson(Map<String, dynamic> json) {
    return WarehouseModel(
      id: _parseInt(json['id']),
      companyId: _parseInt(json['company_id']),
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      branchId: _nullableInt(json['branch_id']),
      locationId: _nullableInt(json['location_id']),
      warehouseType: json['warehouse_type']?.toString(),
      parentWarehouseId: _nullableInt(json['parent_warehouse_id']),
      allowNegativeStock:
          json['allow_negative_stock'] == true ||
          json['allow_negative_stock'] == 1,
      isSellableStock:
          json['is_sellable_stock'] != false && json['is_sellable_stock'] != 0,
      isReservedOnly:
          json['is_reserved_only'] == true || json['is_reserved_only'] == 1,
      isDefault: json['is_default'] == true || json['is_default'] == 1,
      isActive: json['is_active'] != false && json['is_active'] != 0,
      remarks: json['remarks']?.toString(),
      raw: json,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (companyId != null) 'company_id': companyId,
      if (branchId != null) 'branch_id': branchId,
      if (locationId != null) 'location_id': locationId,
      if (code != null) 'code': code,
      if (name != null) 'name': name,
      if (warehouseType != null) 'warehouse_type': warehouseType,
      if (parentWarehouseId != null) 'parent_warehouse_id': parentWarehouseId,
      'allow_negative_stock': allowNegativeStock,
      'is_sellable_stock': isSellableStock,
      'is_reserved_only': isReservedOnly,
      'is_default': isDefault,
      'is_active': isActive,
      if (remarks != null) 'remarks': remarks,
    };
  }

  static int _parseInt(dynamic value) =>
      int.tryParse(value?.toString() ?? '') ?? 0;

  static int? _nullableInt(dynamic value) {
    final parsed = int.tryParse(value?.toString() ?? '');
    return parsed == null || parsed == 0 ? null : parsed;
  }
}
