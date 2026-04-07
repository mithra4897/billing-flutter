import '../common/json_model.dart';

class StockBalanceModel implements JsonModel {
  const StockBalanceModel({
    this.id,
    this.companyId,
    this.branchId,
    this.locationId,
    this.itemId,
    this.warehouseId,
    this.batchId,
    this.serialId,
    this.qtyOnHand,
    this.qtyReserved,
    this.qtyAvailable,
    this.avgCost,
    this.lastPurchaseRate,
    this.lastSalesRate,
    this.lastMovementAt,
    this.itemCode = '',
    this.itemName = '',
    this.itemType,
    this.warehouseCode,
    this.warehouseName,
    this.batchNo,
    this.serialNo,
    this.raw,
  });

  final int? id;
  final int? companyId;
  final int? branchId;
  final int? locationId;
  final int? itemId;
  final int? warehouseId;
  final int? batchId;
  final int? serialId;
  final double? qtyOnHand;
  final double? qtyReserved;
  final double? qtyAvailable;
  final double? avgCost;
  final double? lastPurchaseRate;
  final double? lastSalesRate;
  final String? lastMovementAt;
  final String itemCode;
  final String itemName;
  final String? itemType;
  final String? warehouseCode;
  final String? warehouseName;
  final String? batchNo;
  final String? serialNo;
  final Map<String, dynamic>? raw;

  @override
  String toString() => itemName.isNotEmpty ? itemName : itemCode;

  factory StockBalanceModel.fromJson(Map<String, dynamic> json) {
    final item = _asMap(json['item']);
    final warehouse = _asMap(json['warehouse']);
    final batch = _asMap(json['batch']);
    final serial = _asMap(json['serial']);

    return StockBalanceModel(
      id: _nullableInt(json['id']),
      companyId: _nullableInt(json['company_id']),
      branchId: _nullableInt(json['branch_id']),
      locationId: _nullableInt(json['location_id']),
      itemId: _nullableInt(json['item_id'] ?? item['id']),
      warehouseId: _nullableInt(json['warehouse_id'] ?? warehouse['id']),
      batchId: _nullableInt(json['batch_id'] ?? batch['id']),
      serialId: _nullableInt(json['serial_id'] ?? serial['id']),
      qtyOnHand: _parseDouble(json['qty_on_hand']),
      qtyReserved: _parseDouble(json['qty_reserved']),
      qtyAvailable: _parseDouble(json['qty_available']),
      avgCost: _parseDouble(json['avg_cost']),
      lastPurchaseRate: _parseDouble(json['last_purchase_rate']),
      lastSalesRate: _parseDouble(json['last_sales_rate']),
      lastMovementAt: json['last_movement_at']?.toString(),
      itemCode: item['item_code']?.toString() ?? '',
      itemName: item['item_name']?.toString() ?? '',
      itemType: item['item_type']?.toString(),
      warehouseCode: warehouse['code']?.toString(),
      warehouseName: warehouse['name']?.toString(),
      batchNo: batch['batch_no']?.toString(),
      serialNo: serial['serial_no']?.toString(),
      raw: json,
    );
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(raw ?? const {});

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    return <String, dynamic>{};
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
