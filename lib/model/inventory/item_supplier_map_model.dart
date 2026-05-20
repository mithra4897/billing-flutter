import '../../screen.dart';

class ItemSupplierMapModel extends JsonModel {
  const ItemSupplierMapModel({
    super.id,
    this.itemId,
    this.supplierId,
    this.purchaseUomId,
    this.supplierItemCode,
    this.supplierItemName,
    this.supplierRate,
    this.leadTimeDays,
    this.minOrderQty,
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
  });
  final int? itemId;
  final int? supplierId;
  final int? purchaseUomId;
  final String? supplierItemCode;
  final String? supplierItemName;
  final double? supplierRate;
  final int? leadTimeDays;
  final double? minOrderQty;
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

  factory ItemSupplierMapModel.fromJson(Map<String, dynamic> json) {
    final item = json['item'] as Map<String, dynamic>?;
    final supplier = json['supplier'] as Map<String, dynamic>?;
    final purchaseUom = json['purchase_uom'] as Map<String, dynamic>?;

    return ItemSupplierMapModel(
      id: JsonModel.nullableInt(json['id']),
      itemId: JsonModel.nullableInt(json['item_id']),
      supplierId: JsonModel.nullableInt(json['supplier_party_id']),
      purchaseUomId: JsonModel.nullableInt(json['purchase_uom_id']),
      supplierItemCode: json['supplier_item_code']?.toString(),
      supplierItemName: json['supplier_item_name']?.toString(),
      supplierRate: JsonModel.nullableDouble(json['supplier_rate']),
      leadTimeDays: JsonModel.nullableInt(json['lead_time_days']),
      minOrderQty: JsonModel.nullableDouble(json['minimum_order_qty']),
      isPrimarySupplier: JsonModel.boolOf(json['is_primary_supplier']),
      isActive: json['is_active'] == null
          ? true
          : JsonModel.boolOf(json['is_active'], fallback: true),
      remarks: json['remarks']?.toString(),
      itemCode: JsonModel.stringOf(item?['item_code']),
      itemName: JsonModel.stringOf(item?['item_name']),
      itemType: JsonModel.stringOf(item?['item_type']),
      supplierCode: JsonModel.stringOf(supplier?['party_code']),
      supplierName: JsonModel.stringOf(supplier?['party_name']),
      supplierType: JsonModel.stringOf(supplier?['party_type_id']),
      purchaseUomCode: JsonModel.stringOf(purchaseUom?['uom_code']),
      purchaseUomName: JsonModel.stringOf(purchaseUom?['uom_name']),
      purchaseUomSymbol: JsonModel.stringOf(purchaseUom?['symbol']),
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
      if (supplierId != null) 'supplier_party_id': supplierId,
      if (supplierItemCode != null && supplierItemCode!.trim().isNotEmpty)
        'supplier_item_code': supplierItemCode,
      if (supplierItemName != null && supplierItemName!.trim().isNotEmpty)
        'supplier_item_name': supplierItemName,
      if (purchaseUomId != null) 'purchase_uom_id': purchaseUomId,
      if (supplierRate != null) 'supplier_rate': supplierRate,
      if (leadTimeDays != null) 'lead_time_days': leadTimeDays,
      if (minOrderQty != null) 'minimum_order_qty': minOrderQty,
      'is_primary_supplier': isPrimarySupplier,
      'is_active': isActive,
      if (remarks != null && remarks!.trim().isNotEmpty) 'remarks': remarks,
    };
  }
}
