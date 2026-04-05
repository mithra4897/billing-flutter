class ItemModel {
  const ItemModel({
    required this.id,
    required this.itemCode,
    required this.itemName,
    this.categoryId,
    this.brandId,
    this.baseUomId,
    this.salesRate,
    this.purchaseRate,
    this.taxCodeId,
    this.imagePath,
    this.trackInventory = false,
    this.isActive = true,
    this.raw,
  });

  final int id;
  final String itemCode;
  final String itemName;
  final int? categoryId;
  final int? brandId;
  final int? baseUomId;
  final double? salesRate;
  final double? purchaseRate;
  final int? taxCodeId;
  final String? imagePath;
  final bool trackInventory;
  final bool isActive;
  final Map<String, dynamic>? raw;

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
      id: _parseInt(json['id']),
      itemCode: json['item_code']?.toString() ?? '',
      itemName: json['item_name']?.toString() ?? '',
      categoryId: _nullableInt(json['category_id']),
      brandId: _nullableInt(json['brand_id']),
      baseUomId: _nullableInt(json['base_uom_id']),
      salesRate: _parseDouble(json['sales_rate']),
      purchaseRate: _parseDouble(json['purchase_rate']),
      taxCodeId: _nullableInt(json['tax_code_id']),
      imagePath: json['image_path']?.toString(),
      trackInventory:
          json['track_inventory'] == true || json['track_inventory'] == 1,
      isActive: json['is_active'] != false && json['is_active'] != 0,
      raw: json,
    );
  }

  static int _parseInt(dynamic value) =>
      int.tryParse(value?.toString() ?? '') ?? 0;

  static int? _nullableInt(dynamic value) {
    final parsed = int.tryParse(value?.toString() ?? '');
    return parsed == null || parsed == 0 ? null : parsed;
  }

  static double? _parseDouble(dynamic value) =>
      double.tryParse(value?.toString() ?? '');
}
