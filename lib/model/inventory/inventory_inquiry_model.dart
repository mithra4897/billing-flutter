import '../../screen.dart';

class InventoryInquirySummaryModel extends JsonModel {
  const InventoryInquirySummaryModel({
    this.itemId,
    this.qtyOnHand = 0,
    this.qtyReserved = 0,
    this.qtyAvailable = 0,
    this.avgCost = 0,
    this.lastPurchaseRate = 0,
    this.lastSalesRate = 0,
  }) : super(id: null);

  final int? itemId;
  final double qtyOnHand;
  final double qtyReserved;
  final double qtyAvailable;
  final double avgCost;
  final double lastPurchaseRate;
  final double lastSalesRate;

  @override
  String toString() => 'Inventory summary';

  factory InventoryInquirySummaryModel.fromJson(Map<String, dynamic> json) {
    return InventoryInquirySummaryModel(
      itemId: JsonModel.nullableInt(json['item_id']),
      qtyOnHand: JsonModel.nullableDouble(json['qty_on_hand']) ?? 0,
      qtyReserved: JsonModel.nullableDouble(json['qty_reserved']) ?? 0,
      qtyAvailable: JsonModel.nullableDouble(json['qty_available']) ?? 0,
      avgCost: JsonModel.nullableDouble(json['avg_cost']) ?? 0,
      lastPurchaseRate:
          JsonModel.nullableDouble(json['last_purchase_rate']) ?? 0,
      lastSalesRate: JsonModel.nullableDouble(json['last_sales_rate']) ?? 0,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'item_id': itemId,
      'qty_on_hand': qtyOnHand,
      'qty_reserved': qtyReserved,
      'qty_available': qtyAvailable,
      'avg_cost': avgCost,
      'last_purchase_rate': lastPurchaseRate,
      'last_sales_rate': lastSalesRate,
    };
  }
}

class InventoryInquiryWarehouseRowModel extends JsonModel {
  const InventoryInquiryWarehouseRowModel({
    this.warehouseId,
    this.warehouseName,
    this.qtyOnHand = 0,
    this.qtyReserved = 0,
    this.qtyAvailable = 0,
    this.avgCost = 0,
  }) : super(id: null);

  final int? warehouseId;
  final String? warehouseName;
  final double qtyOnHand;
  final double qtyReserved;
  final double qtyAvailable;
  final double avgCost;

  @override
  String toString() => warehouseName ?? 'Warehouse stock';

  factory InventoryInquiryWarehouseRowModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final warehouse = _asMap(json['warehouse']);
    return InventoryInquiryWarehouseRowModel(
      warehouseId: JsonModel.nullableInt(json['warehouse_id']),
      warehouseName:
          warehouse['name']?.toString() ?? warehouse['code']?.toString(),
      qtyOnHand: JsonModel.nullableDouble(json['qty_on_hand']) ?? 0,
      qtyReserved: JsonModel.nullableDouble(json['qty_reserved']) ?? 0,
      qtyAvailable: JsonModel.nullableDouble(json['qty_available']) ?? 0,
      avgCost: JsonModel.nullableDouble(json['avg_cost']) ?? 0,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'warehouse_id': warehouseId,
      'warehouse_name': warehouseName,
      'qty_on_hand': qtyOnHand,
      'qty_reserved': qtyReserved,
      'qty_available': qtyAvailable,
      'avg_cost': avgCost,
    };
  }
}

class InventoryInquiryBatchRowModel extends JsonModel {
  const InventoryInquiryBatchRowModel({
    this.batchId,
    this.batchNo,
    this.warehouseId,
    this.warehouseName,
    this.mfgDate,
    this.expiryDate,
    this.balanceQty = 0,
    this.isExpired = false,
  }) : super(id: null);

  final int? batchId;
  final String? batchNo;
  final int? warehouseId;
  final String? warehouseName;
  final String? mfgDate;
  final String? expiryDate;
  final double balanceQty;
  final bool isExpired;

  @override
  String toString() => batchNo ?? 'Batch stock';

  factory InventoryInquiryBatchRowModel.fromJson(Map<String, dynamic> json) {
    final warehouse = _asMap(json['warehouse']);
    return InventoryInquiryBatchRowModel(
      batchId: JsonModel.nullableInt(json['batch_id']),
      batchNo: json['batch_no']?.toString(),
      warehouseId: JsonModel.nullableInt(json['warehouse_id']),
      warehouseName:
          warehouse['name']?.toString() ?? warehouse['code']?.toString(),
      mfgDate: json['mfg_date']?.toString(),
      expiryDate: json['expiry_date']?.toString(),
      balanceQty: JsonModel.nullableDouble(json['balance_qty']) ?? 0,
      isExpired:
          json['is_expired'] == true ||
          json['is_expired'] == 1 ||
          json['is_expired']?.toString() == '1',
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'batch_id': batchId,
      'batch_no': batchNo,
      'warehouse_id': warehouseId,
      'warehouse_name': warehouseName,
      'mfg_date': mfgDate,
      'expiry_date': expiryDate,
      'balance_qty': balanceQty,
      'is_expired': isExpired,
    };
  }
}

class InventoryInquirySerialRowModel extends JsonModel {
  const InventoryInquirySerialRowModel({
    this.serialId,
    this.serialNo,
    this.warehouseName,
    this.batchNo,
    this.status,
    this.inwardDate,
    this.outwardDate,
  }) : super(id: null);

  final int? serialId;
  final String? serialNo;
  final String? warehouseName;
  final String? batchNo;
  final String? status;
  final String? inwardDate;
  final String? outwardDate;

  @override
  String toString() => serialNo ?? 'Serial stock';

  factory InventoryInquirySerialRowModel.fromJson(Map<String, dynamic> json) {
    final warehouse = _asMap(json['warehouse']);
    final batch = _asMap(json['batch']);
    return InventoryInquirySerialRowModel(
      serialId: JsonModel.nullableInt(json['serial_id']),
      serialNo: json['serial_no']?.toString(),
      warehouseName:
          warehouse['name']?.toString() ?? warehouse['code']?.toString(),
      batchNo: batch['batch_no']?.toString(),
      status: json['status']?.toString(),
      inwardDate: json['inward_date']?.toString(),
      outwardDate: json['outward_date']?.toString(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'serial_id': serialId,
      'serial_no': serialNo,
      'warehouse_name': warehouseName,
      'batch_no': batchNo,
      'status': status,
      'inward_date': inwardDate,
      'outward_date': outwardDate,
    };
  }
}

class InventoryInquiryReorderStatusModel extends JsonModel {
  const InventoryInquiryReorderStatusModel({
    this.itemId,
    this.itemCode,
    this.itemName,
    this.availableQty = 0,
    this.minStockLevel = 0,
    this.reorderLevel = 0,
    this.reorderQty = 0,
    this.isBelowMinStock = false,
    this.isBelowReorder = false,
  }) : super(id: null);

  final int? itemId;
  final String? itemCode;
  final String? itemName;
  final double availableQty;
  final double minStockLevel;
  final double reorderLevel;
  final double reorderQty;
  final bool isBelowMinStock;
  final bool isBelowReorder;

  @override
  String toString() => itemName ?? itemCode ?? 'Reorder status';

  factory InventoryInquiryReorderStatusModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return InventoryInquiryReorderStatusModel(
      itemId: JsonModel.nullableInt(json['item_id']),
      itemCode: json['item_code']?.toString(),
      itemName: json['item_name']?.toString(),
      availableQty: JsonModel.nullableDouble(json['available_qty']) ?? 0,
      minStockLevel: JsonModel.nullableDouble(json['min_stock_level']) ?? 0,
      reorderLevel: JsonModel.nullableDouble(json['reorder_level']) ?? 0,
      reorderQty: JsonModel.nullableDouble(json['reorder_qty']) ?? 0,
      isBelowMinStock:
          json['is_below_min_stock'] == true ||
          json['is_below_min_stock'] == 1 ||
          json['is_below_min_stock']?.toString() == '1',
      isBelowReorder:
          json['is_below_reorder'] == true ||
          json['is_below_reorder'] == 1 ||
          json['is_below_reorder']?.toString() == '1',
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'item_id': itemId,
      'item_code': itemCode,
      'item_name': itemName,
      'available_qty': availableQty,
      'min_stock_level': minStockLevel,
      'reorder_level': reorderLevel,
      'reorder_qty': reorderQty,
      'is_below_min_stock': isBelowMinStock,
      'is_below_reorder': isBelowReorder,
    };
  }
}

class InventoryInquiryStockCardModel extends JsonModel {
  const InventoryInquiryStockCardModel({
    this.item,
    this.summary,
    this.warehouseRows = const <InventoryInquiryWarehouseRowModel>[],
    this.batchRows = const <InventoryInquiryBatchRowModel>[],
    this.serialRows = const <InventoryInquirySerialRowModel>[],
  }) : super(id: null);

  final ItemModel? item;
  final InventoryInquirySummaryModel? summary;
  final List<InventoryInquiryWarehouseRowModel> warehouseRows;
  final List<InventoryInquiryBatchRowModel> batchRows;
  final List<InventoryInquirySerialRowModel> serialRows;

  @override
  String toString() => item?.toString() ?? 'Stock card';

  factory InventoryInquiryStockCardModel.fromJson(Map<String, dynamic> json) {
    return InventoryInquiryStockCardModel(
      item: _asMap(json['item']).isEmpty
          ? null
          : ItemModel.fromJson(_asMap(json['item'])),
      summary: _asMap(json['summary']).isEmpty
          ? null
          : InventoryInquirySummaryModel.fromJson(_asMap(json['summary'])),
      warehouseRows: _asList(
        json['warehouse_wise'],
      ).map(InventoryInquiryWarehouseRowModel.fromJson).toList(growable: false),
      batchRows: _asList(
        json['batch_wise'],
      ).map(InventoryInquiryBatchRowModel.fromJson).toList(growable: false),
      serialRows: _asList(
        json['available_serials'],
      ).map(InventoryInquirySerialRowModel.fromJson).toList(growable: false),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'item': item?.toJson(),
      'summary': summary?.toJson(),
      'warehouse_wise': warehouseRows.map((row) => row.toJson()).toList(),
      'batch_wise': batchRows.map((row) => row.toJson()).toList(),
      'available_serials': serialRows.map((row) => row.toJson()).toList(),
    };
  }
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return const <String, dynamic>{};
}

List<Map<String, dynamic>> _asList(dynamic value) {
  if (value is List<Map<String, dynamic>>) {
    return value;
  }
  if (value is List) {
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }
  return const <Map<String, dynamic>>[];
}
