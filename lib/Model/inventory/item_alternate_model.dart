import '../common/json_model.dart';

class ItemAlternateModel implements JsonModel {
  const ItemAlternateModel({
    this.id,
    this.itemId,
    this.alternateItemId,
    this.priority,
    this.isActive = true,
    this.remarks,
    this.itemCode = '',
    this.itemName = '',
    this.itemType,
    this.alternateItemCode = '',
    this.alternateItemName = '',
    this.alternateItemType,
    this.raw,
  });

  final int? id;
  final int? itemId;
  final int? alternateItemId;
  final int? priority;
  final bool isActive;
  final String? remarks;
  final String itemCode;
  final String itemName;
  final String? itemType;
  final String alternateItemCode;
  final String alternateItemName;
  final String? alternateItemType;
  final Map<String, dynamic>? raw;

  @override
  String toString() =>
      alternateItemName.isNotEmpty ? alternateItemName : alternateItemCode;

  factory ItemAlternateModel.fromJson(Map<String, dynamic> json) {
    final item = _asMap(json['item']);
    final alternate = _asMap(json['alternate_item'] ?? json['alternateItem']);
    return ItemAlternateModel(
      id: _nullableInt(json['id']),
      itemId: _nullableInt(json['item_id'] ?? item['id']),
      alternateItemId: _nullableInt(
        json['alternate_item_id'] ?? alternate['id'],
      ),
      priority: _nullableInt(json['priority']),
      isActive: _bool(json['is_active'], fallback: true),
      remarks: json['remarks']?.toString(),
      itemCode: item['item_code']?.toString() ?? '',
      itemName: item['item_name']?.toString() ?? '',
      itemType: item['item_type']?.toString(),
      alternateItemCode: alternate['item_code']?.toString() ?? '',
      alternateItemName: alternate['item_name']?.toString() ?? '',
      alternateItemType: alternate['item_type']?.toString(),
      raw: json,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (itemId != null) 'item_id': itemId,
      if (alternateItemId != null) 'alternate_item_id': alternateItemId,
      if (priority != null) 'priority': priority,
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
}
