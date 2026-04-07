import '../common/json_model.dart';
import '../common/model_value.dart';

class ItemSupplierMapModel implements JsonModel {
  const ItemSupplierMapModel({
    this.id,
    this.itemId,
    this.supplierId,
    this.purchaseUomId,
    this.supplierItemCode,
    this.supplierItemName,
    this.leadTimeDays,
    this.minOrderQty,
    this.supplierPriority,
    this.isPrimarySupplier = false,
    this.isActive = true,
    this.remarks,
    this.itemCode = '',
    this.itemName = '',
    this.itemType = '',
    this.supplierCode = '',
    this.supplierName = '',
    this.supplierType = '',
    this.purchaseUomCode = '',
    this.purchaseUomName = '',
    this.purchaseUomSymbol = '',
    this.raw,
  });

  final int? id;
  final int? itemId;
  final int? supplierId;
  final int? purchaseUomId;
  final String? supplierItemCode;
  final String? supplierItemName;
  final int? leadTimeDays;
  final double? minOrderQty;
  final int? supplierPriority;
  final bool isPrimarySupplier;
  final bool isActive;
  final String? remarks;
  final String itemCode;
  final String itemName;
  final String itemType;
  final String supplierCode;
  final String supplierName;
  final String supplierType;
  final String purchaseUomCode;
  final String purchaseUomName;
  final String purchaseUomSymbol;
  final Map<String, dynamic>? raw;

  factory ItemSupplierMapModel.fromJson(Map<String, dynamic> json) {
    final item = json['item'] as Map<String, dynamic>?;
    final supplier = json['supplier'] as Map<String, dynamic>?;
    final purchaseUom = json['purchase_uom'] as Map<String, dynamic>?;

    return ItemSupplierMapModel(
      id: ModelValue.nullableInt(json['id']),
      itemId: ModelValue.nullableInt(json['item_id']),
      supplierId: ModelValue.nullableInt(json['supplier_id']),
      purchaseUomId: ModelValue.nullableInt(json['purchase_uom_id']),
      supplierItemCode: json['supplier_item_code']?.toString(),
      supplierItemName: json['supplier_item_name']?.toString(),
      leadTimeDays: ModelValue.nullableInt(json['lead_time_days']),
      minOrderQty: ModelValue.nullableDouble(json['min_order_qty']),
      supplierPriority: ModelValue.nullableInt(json['supplier_priority']),
      isPrimarySupplier: ModelValue.boolOf(json['is_primary_supplier']),
      isActive: json['is_active'] == null
          ? true
          : ModelValue.boolOf(json['is_active'], fallback: true),
      remarks: json['remarks']?.toString(),
      itemCode: ModelValue.stringOf(item?['item_code']),
      itemName: ModelValue.stringOf(item?['item_name']),
      itemType: ModelValue.stringOf(item?['item_type']),
      supplierCode: ModelValue.stringOf(supplier?['party_code']),
      supplierName: ModelValue.stringOf(supplier?['party_name']),
      supplierType: ModelValue.stringOf(supplier?['party_type']),
      purchaseUomCode: ModelValue.stringOf(purchaseUom?['uom_code']),
      purchaseUomName: ModelValue.stringOf(purchaseUom?['uom_name']),
      purchaseUomSymbol: ModelValue.stringOf(purchaseUom?['symbol']),
      raw: json,
    );
  }

  @override
  String toString() {
    if (supplierName.trim().isNotEmpty) {
      return supplierName;
    }
    if (itemName.trim().isNotEmpty) {
      return itemName;
    }
    return 'New Item Supplier Map';
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (itemId != null) 'item_id': itemId,
      if (supplierId != null) 'supplier_id': supplierId,
      if (supplierItemCode != null && supplierItemCode!.trim().isNotEmpty)
        'supplier_item_code': supplierItemCode,
      if (supplierItemName != null && supplierItemName!.trim().isNotEmpty)
        'supplier_item_name': supplierItemName,
      if (purchaseUomId != null) 'purchase_uom_id': purchaseUomId,
      if (leadTimeDays != null) 'lead_time_days': leadTimeDays,
      if (minOrderQty != null) 'min_order_qty': minOrderQty,
      if (supplierPriority != null) 'supplier_priority': supplierPriority,
      'is_primary_supplier': isPrimarySupplier,
      'is_active': isActive,
      if (remarks != null && remarks!.trim().isNotEmpty) 'remarks': remarks,
    };
  }
}
