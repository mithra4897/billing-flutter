import '../common/json_model.dart';

class ItemModel implements JsonModel {
  const ItemModel({
    this.id,
    this.companyId,
    this.companyCode,
    this.companyName,
    this.itemCode = '',
    this.itemName = '',
    this.itemNameLocal,
    this.itemType,
    this.categoryId,
    this.categoryCode,
    this.categoryName,
    this.brandId,
    this.brandCode,
    this.brandName,
    this.baseUomId,
    this.baseUomCode,
    this.baseUomName,
    this.baseUomSymbol,
    this.purchaseUomId,
    this.purchaseUomCode,
    this.purchaseUomName,
    this.purchaseUomSymbol,
    this.salesUomId,
    this.salesUomCode,
    this.salesUomName,
    this.salesUomSymbol,
    this.taxCodeId,
    this.taxCode,
    this.taxName,
    this.sku,
    this.barcode,
    this.hsnSacCode,
    this.standardCost,
    this.standardSellingPrice,
    this.mrp,
    this.minStockLevel,
    this.reorderLevel,
    this.reorderQty,
    this.weight,
    this.volume,
    this.imagePath,
    this.hasBatch = false,
    this.hasSerial = false,
    this.hasExpiry = false,
    this.trackInventory = false,
    this.isSaleable = true,
    this.isPurchaseable = true,
    this.isManufacturable = false,
    this.isJobworkApplicable = false,
    this.isActive = true,
    this.remarks,
    this.raw,
  });

  final int? id;
  final int? companyId;
  final String? companyCode;
  final String? companyName;
  final String itemCode;
  final String itemName;
  final String? itemNameLocal;
  final String? itemType;
  final int? categoryId;
  final String? categoryCode;
  final String? categoryName;
  final int? brandId;
  final String? brandCode;
  final String? brandName;
  final int? baseUomId;
  final String? baseUomCode;
  final String? baseUomName;
  final String? baseUomSymbol;
  final int? purchaseUomId;
  final String? purchaseUomCode;
  final String? purchaseUomName;
  final String? purchaseUomSymbol;
  final int? salesUomId;
  final String? salesUomCode;
  final String? salesUomName;
  final String? salesUomSymbol;
  final int? taxCodeId;
  final String? taxCode;
  final String? taxName;
  final String? sku;
  final String? barcode;
  final String? hsnSacCode;
  final double? standardCost;
  final double? standardSellingPrice;
  final double? mrp;
  final double? minStockLevel;
  final double? reorderLevel;
  final double? reorderQty;
  final double? weight;
  final double? volume;
  final String? imagePath;
  final bool hasBatch;
  final bool hasSerial;
  final bool hasExpiry;
  final bool trackInventory;
  final bool isSaleable;
  final bool isPurchaseable;
  final bool isManufacturable;
  final bool isJobworkApplicable;
  final bool isActive;
  final String? remarks;
  final Map<String, dynamic>? raw;

  @override
  String toString() => itemName.isNotEmpty ? itemName : itemCode;

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    final company = _asMap(json['company']);
    final category = _asMap(json['category']);
    final brand = _asMap(json['brand']);
    final baseUom = _asMap(json['base_uom'] ?? json['baseUom']);
    final purchaseUom = _asMap(json['purchase_uom'] ?? json['purchaseUom']);
    final salesUom = _asMap(json['sales_uom'] ?? json['salesUom']);
    final taxCode = _asMap(json['tax_code'] ?? json['taxCode']);

    return ItemModel(
      id: _nullableInt(json['id']),
      companyId: _nullableInt(json['company_id'] ?? company['id']),
      companyCode:
          company['company_code']?.toString() ?? company['code']?.toString(),
      companyName:
          company['company_name']?.toString() ??
          company['trade_name']?.toString() ??
          company['legal_name']?.toString(),
      itemCode: json['item_code']?.toString() ?? '',
      itemName: json['item_name']?.toString() ?? '',
      itemNameLocal: json['item_name_local']?.toString(),
      itemType: json['item_type']?.toString(),
      categoryId: _nullableInt(json['category_id'] ?? category['id']),
      categoryCode: category['category_code']?.toString(),
      categoryName: category['category_name']?.toString(),
      brandId: _nullableInt(json['brand_id'] ?? brand['id']),
      brandCode: brand['brand_code']?.toString(),
      brandName: brand['brand_name']?.toString(),
      baseUomId: _nullableInt(json['base_uom_id'] ?? baseUom['id']),
      baseUomCode:
          baseUom['uom_code']?.toString() ?? baseUom['code']?.toString(),
      baseUomName:
          baseUom['uom_name']?.toString() ?? baseUom['name']?.toString(),
      baseUomSymbol: baseUom['symbol']?.toString(),
      purchaseUomId: _nullableInt(json['purchase_uom_id'] ?? purchaseUom['id']),
      purchaseUomCode:
          purchaseUom['uom_code']?.toString() ??
          purchaseUom['code']?.toString(),
      purchaseUomName:
          purchaseUom['uom_name']?.toString() ??
          purchaseUom['name']?.toString(),
      purchaseUomSymbol: purchaseUom['symbol']?.toString(),
      salesUomId: _nullableInt(json['sales_uom_id'] ?? salesUom['id']),
      salesUomCode:
          salesUom['uom_code']?.toString() ?? salesUom['code']?.toString(),
      salesUomName:
          salesUom['uom_name']?.toString() ?? salesUom['name']?.toString(),
      salesUomSymbol: salesUom['symbol']?.toString(),
      taxCodeId: _nullableInt(json['tax_code_id'] ?? taxCode['id']),
      taxCode: taxCode['tax_code']?.toString() ?? taxCode['code']?.toString(),
      taxName: taxCode['tax_name']?.toString() ?? taxCode['name']?.toString(),
      sku: json['sku']?.toString(),
      barcode: json['barcode']?.toString(),
      hsnSacCode: json['hsn_sac_code']?.toString(),
      standardCost: _parseDouble(json['standard_cost']),
      standardSellingPrice: _parseDouble(json['standard_selling_price']),
      mrp: _parseDouble(json['mrp']),
      minStockLevel: _parseDouble(json['min_stock_level']),
      reorderLevel: _parseDouble(json['reorder_level']),
      reorderQty: _parseDouble(json['reorder_qty']),
      weight: _parseDouble(json['weight']),
      volume: _parseDouble(json['volume']),
      imagePath: json['image_path']?.toString(),
      hasBatch: _bool(json['has_batch']),
      hasSerial: _bool(json['has_serial']),
      hasExpiry: _bool(json['has_expiry']),
      trackInventory: _bool(json['track_inventory']),
      isSaleable: _bool(json['is_saleable'], fallback: true),
      isPurchaseable: _bool(json['is_purchaseable'], fallback: true),
      isManufacturable: _bool(json['is_manufacturable']),
      isJobworkApplicable: _bool(json['is_jobwork_applicable']),
      isActive: _bool(json['is_active'], fallback: true),
      remarks: json['remarks']?.toString(),
      raw: json,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (companyId != null) 'company_id': companyId,
      'item_code': itemCode,
      'item_name': itemName,
      if (itemNameLocal != null) 'item_name_local': itemNameLocal,
      if (itemType != null) 'item_type': itemType,
      if (categoryId != null) 'category_id': categoryId,
      if (brandId != null) 'brand_id': brandId,
      if (baseUomId != null) 'base_uom_id': baseUomId,
      if (purchaseUomId != null) 'purchase_uom_id': purchaseUomId,
      if (salesUomId != null) 'sales_uom_id': salesUomId,
      if (taxCodeId != null) 'tax_code_id': taxCodeId,
      if (sku != null) 'sku': sku,
      if (barcode != null) 'barcode': barcode,
      if (hsnSacCode != null) 'hsn_sac_code': hsnSacCode,
      'has_batch': hasBatch,
      'has_serial': hasSerial,
      'has_expiry': hasExpiry,
      'track_inventory': trackInventory,
      'is_saleable': isSaleable,
      'is_purchaseable': isPurchaseable,
      'is_manufacturable': isManufacturable,
      'is_jobwork_applicable': isJobworkApplicable,
      if (standardCost != null) 'standard_cost': standardCost,
      if (standardSellingPrice != null)
        'standard_selling_price': standardSellingPrice,
      if (mrp != null) 'mrp': mrp,
      if (minStockLevel != null) 'min_stock_level': minStockLevel,
      if (reorderLevel != null) 'reorder_level': reorderLevel,
      if (reorderQty != null) 'reorder_qty': reorderQty,
      if (weight != null) 'weight': weight,
      if (volume != null) 'volume': volume,
      if (imagePath != null) 'image_path': imagePath,
      'is_active': isActive,
      if (remarks != null) 'remarks': remarks,
    };
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    return <String, dynamic>{};
  }

  static bool _bool(dynamic value, {bool fallback = false}) {
    if (value == null) {
      return fallback;
    }
    return value == true || value == 1 || value.toString() == '1';
  }

  static int? _nullableInt(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return null;
    }
    return int.tryParse(value.toString());
  }

  static double? _parseDouble(dynamic value) =>
      double.tryParse(value?.toString() ?? '');
}
