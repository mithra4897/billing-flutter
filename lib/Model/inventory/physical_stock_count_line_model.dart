import '../common/json_model.dart';

class PhysicalStockCountLineModel implements JsonModel {
  const PhysicalStockCountLineModel({
    this.id,
    this.itemId,
    this.uomId,
    this.batchId,
    this.serialId,
    this.systemQty,
    this.countedQty,
    this.varianceQty,
    this.unitCost,
    this.varianceValue,
    this.varianceType,
    this.isReconciled = false,
    this.remarks,
    this.itemCode = '',
    this.itemName = '',
    this.batchNo,
    this.serialNo,
    this.uomCode,
    this.uomName,
    this.uomSymbol,
    this.raw,
  });

  final int? id;
  final int? itemId;
  final int? uomId;
  final int? batchId;
  final int? serialId;
  final double? systemQty;
  final double? countedQty;
  final double? varianceQty;
  final double? unitCost;
  final double? varianceValue;
  final String? varianceType;
  final bool isReconciled;
  final String? remarks;
  final String itemCode;
  final String itemName;
  final String? batchNo;
  final String? serialNo;
  final String? uomCode;
  final String? uomName;
  final String? uomSymbol;
  final Map<String, dynamic>? raw;

  @override
  String toString() => itemName.isNotEmpty ? itemName : itemCode;

  factory PhysicalStockCountLineModel.fromJson(Map<String, dynamic> json) {
    final item = _asMap(json['item']);
    final batch = _asMap(json['batch']);
    final serial = _asMap(json['serial']);
    final uom = _asMap(json['uom']);
    return PhysicalStockCountLineModel(
      id: _nullableInt(json['id']),
      itemId: _nullableInt(json['item_id'] ?? item['id']),
      uomId: _nullableInt(json['uom_id'] ?? uom['id']),
      batchId: _nullableInt(json['batch_id'] ?? batch['id']),
      serialId: _nullableInt(json['serial_id'] ?? serial['id']),
      systemQty: _parseDouble(json['system_qty']),
      countedQty: _parseDouble(json['counted_qty']),
      varianceQty: _parseDouble(json['variance_qty']),
      unitCost: _parseDouble(json['unit_cost']),
      varianceValue: _parseDouble(json['variance_value']),
      varianceType: json['variance_type']?.toString(),
      isReconciled: _bool(json['is_reconciled']),
      remarks: json['remarks']?.toString(),
      itemCode: item['item_code']?.toString() ?? '',
      itemName: item['item_name']?.toString() ?? '',
      batchNo: batch['batch_no']?.toString(),
      serialNo: serial['serial_no']?.toString(),
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
      if (uomId != null) 'uom_id': uomId,
      if (batchId != null) 'batch_id': batchId,
      if (serialId != null) 'serial_id': serialId,
      if (systemQty != null) 'system_qty': systemQty,
      if (countedQty != null) 'counted_qty': countedQty,
      if (varianceQty != null) 'variance_qty': varianceQty,
      if (unitCost != null) 'unit_cost': unitCost,
      if (varianceValue != null) 'variance_value': varianceValue,
      if (varianceType != null) 'variance_type': varianceType,
      'is_reconciled': isReconciled,
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
