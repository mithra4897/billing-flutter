import '../common/json_model.dart';

class ItemPriceModel implements JsonModel {
  const ItemPriceModel({
    this.id,
    this.itemId,
    this.priceType,
    this.uomId,
    this.price,
    this.mrp,
    this.minPrice,
    this.maxDiscountPercent,
    this.validFrom,
    this.validTo,
    this.isDefault = false,
    this.isActive = true,
    this.remarks,
    this.itemCode = '',
    this.itemName = '',
    this.itemType,
    this.uomCode,
    this.uomName,
    this.uomSymbol,
    this.raw,
  });

  final int? id;
  final int? itemId;
  final String? priceType;
  final int? uomId;
  final double? price;
  final double? mrp;
  final double? minPrice;
  final double? maxDiscountPercent;
  final String? validFrom;
  final String? validTo;
  final bool isDefault;
  final bool isActive;
  final String? remarks;
  final String itemCode;
  final String itemName;
  final String? itemType;
  final String? uomCode;
  final String? uomName;
  final String? uomSymbol;
  final Map<String, dynamic>? raw;

  @override
  String toString() => itemName.isNotEmpty ? itemName : itemCode;

  factory ItemPriceModel.fromJson(Map<String, dynamic> json) {
    final item = _asMap(json['item']);
    final uom = _asMap(json['uom']);
    return ItemPriceModel(
      id: _nullableInt(json['id']),
      itemId: _nullableInt(json['item_id'] ?? item['id']),
      priceType: json['price_type']?.toString(),
      uomId: _nullableInt(json['uom_id'] ?? uom['id']),
      price: _parseDouble(json['price']),
      mrp: _parseDouble(json['mrp']),
      minPrice: _parseDouble(json['min_price']),
      maxDiscountPercent: _parseDouble(json['max_discount_percent']),
      validFrom: json['valid_from']?.toString(),
      validTo: json['valid_to']?.toString(),
      isDefault: _bool(json['is_default']),
      isActive: _bool(json['is_active'], fallback: true),
      remarks: json['remarks']?.toString(),
      itemCode: item['item_code']?.toString() ?? '',
      itemName: item['item_name']?.toString() ?? '',
      itemType: item['item_type']?.toString(),
      uomCode: uom['uom_code']?.toString() ?? uom['code']?.toString(),
      uomName: uom['uom_name']?.toString() ?? uom['name']?.toString(),
      uomSymbol: uom['symbol']?.toString(),
      raw: json,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (itemId != null) 'item_id': itemId,
      if (priceType != null) 'price_type': priceType,
      if (uomId != null) 'uom_id': uomId,
      if (price != null) 'price': price,
      if (mrp != null) 'mrp': mrp,
      if (minPrice != null) 'min_price': minPrice,
      if (maxDiscountPercent != null)
        'max_discount_percent': maxDiscountPercent,
      if (validFrom != null) 'valid_from': validFrom,
      if (validTo != null) 'valid_to': validTo,
      'is_default': isDefault,
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
