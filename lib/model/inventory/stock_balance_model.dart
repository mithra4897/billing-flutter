import '../../screen.dart';

class StockBalanceModel extends JsonModel {
  const StockBalanceModel({
    super.id,
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
    this.categoryId,
    this.categoryCode,
    this.categoryName,
    this.warehouseCode,
    this.warehouseName,
    this.batchNo,
    this.serialNo,
  });
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
  final int? categoryId;
  final String? categoryCode;
  final String? categoryName;
  final String? warehouseCode;
  final String? warehouseName;
  final String? batchNo;
  final String? serialNo;

  @override
  String toString() => itemName.isNotEmpty ? itemName : itemCode;

  factory StockBalanceModel.fromJson(Map<String, dynamic> json) {
    final item = _asMap(json['item']);
    final category = _asMap(item['category']);
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
      categoryId: _nullableInt(item['category_id'] ?? category['id']),
      categoryCode:
          item['category_code']?.toString() ??
          category['category_code']?.toString(),
      categoryName:
          item['category_name']?.toString() ??
          category['category_name']?.toString(),
      warehouseCode: warehouse['code']?.toString(),
      warehouseName: warehouse['name']?.toString(),
      batchNo: batch['batch_no']?.toString(),
      serialNo: serial['serial_no']?.toString(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (companyId != null) 'company_id': companyId,
    if (branchId != null) 'branch_id': branchId,
    if (locationId != null) 'location_id': locationId,
    if (itemId != null) 'item_id': itemId,
    if (warehouseId != null) 'warehouse_id': warehouseId,
    if (batchId != null) 'batch_id': batchId,
    if (serialId != null) 'serial_id': serialId,
    if (qtyOnHand != null) 'qty_on_hand': qtyOnHand,
    if (qtyReserved != null) 'qty_reserved': qtyReserved,
    if (qtyAvailable != null) 'qty_available': qtyAvailable,
    if (avgCost != null) 'avg_cost': avgCost,
    if (lastPurchaseRate != null) 'last_purchase_rate': lastPurchaseRate,
    if (lastSalesRate != null) 'last_sales_rate': lastSalesRate,
    if (lastMovementAt != null) 'last_movement_at': lastMovementAt,
    'item_code': itemCode,
    'item_name': itemName,
    if (itemType != null) 'item_type': itemType,
    if (categoryId != null) 'category_id': categoryId,
    if (categoryCode != null) 'category_code': categoryCode,
    if (categoryName != null) 'category_name': categoryName,
    if (warehouseCode != null) 'warehouse_code': warehouseCode,
    if (warehouseName != null) 'warehouse_name': warehouseName,
    if (batchNo != null) 'batch_no': batchNo,
    if (serialNo != null) 'serial_no': serialNo,
  };

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
