import '../../screen.dart';

class ProduceTrackingLineModel extends JsonModel {
  const ProduceTrackingLineModel({
    super.id,
    this.produceTrackingId,
    this.salesDeliveryLineId,
    this.purchaseOrderLineId,
    this.lineNo,
    this.itemId,
    this.warehouseId,
    this.uomId,
    this.batchId,
    this.serialId,
    this.trackedQty,
    this.deliveredQty,
    this.receivedQty,
    this.balanceQty,
    this.lineStatus,
    this.currentLocation,
    this.lastLocationUpdateAt,
    this.remarks,
    this.createdAt,
  });

  final int? produceTrackingId;
  final int? salesDeliveryLineId;
  final int? purchaseOrderLineId;
  final int? lineNo;
  final int? itemId;
  final int? warehouseId;
  final int? uomId;
  final int? batchId;
  final int? serialId;
  final double? trackedQty;
  final double? deliveredQty;
  final double? receivedQty;
  final double? balanceQty;
  final String? lineStatus;
  final String? currentLocation;
  final String? lastLocationUpdateAt;
  final String? remarks;
  final String? createdAt;

  factory ProduceTrackingLineModel.fromJson(Map<String, dynamic> json) {
    return ProduceTrackingLineModel(
      id: JsonModel.nullableInt(json['id']),
      produceTrackingId: JsonModel.nullableInt(json['produce_tracking_id']),
      salesDeliveryLineId: JsonModel.nullableInt(json['sales_delivery_line_id']),
      purchaseOrderLineId: JsonModel.nullableInt(json['purchase_order_line_id']),
      lineNo: JsonModel.nullableInt(json['line_no']),
      itemId: JsonModel.nullableInt(json['item_id']),
      warehouseId: JsonModel.nullableInt(json['warehouse_id']),
      uomId: JsonModel.nullableInt(json['uom_id']),
      batchId: JsonModel.nullableInt(json['batch_id']),
      serialId: JsonModel.nullableInt(json['serial_id']),
      trackedQty: JsonModel.nullableDouble(json['tracked_qty']),
      deliveredQty: JsonModel.nullableDouble(json['delivered_qty']),
      receivedQty: JsonModel.nullableDouble(json['received_qty']),
      balanceQty: JsonModel.nullableDouble(json['balance_qty']),
      lineStatus: json['line_status']?.toString(),
      currentLocation: json['current_location']?.toString(),
      lastLocationUpdateAt: json['last_location_update_at']?.toString(),
      remarks: json['remarks']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }

  @override
  String toString() =>
      JsonModel.combineValues([lineNo, itemId], defaultValue: 'Tracking Line');

  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (produceTrackingId != null) 'produce_tracking_id': produceTrackingId,
    if (salesDeliveryLineId != null) 'sales_delivery_line_id': salesDeliveryLineId,
    if (purchaseOrderLineId != null) 'purchase_order_line_id': purchaseOrderLineId,
    if (lineNo != null) 'line_no': lineNo,
    if (itemId != null) 'item_id': itemId,
    if (warehouseId != null) 'warehouse_id': warehouseId,
    if (uomId != null) 'uom_id': uomId,
    if (batchId != null) 'batch_id': batchId,
    if (serialId != null) 'serial_id': serialId,
    if (trackedQty != null) 'tracked_qty': trackedQty,
    if (deliveredQty != null) 'delivered_qty': deliveredQty,
    if (receivedQty != null) 'received_qty': receivedQty,
    if (balanceQty != null) 'balance_qty': balanceQty,
    if (lineStatus != null) 'line_status': lineStatus,
    if (currentLocation != null) 'current_location': currentLocation,
    if (lastLocationUpdateAt != null)
      'last_location_update_at': lastLocationUpdateAt,
    if (remarks != null) 'remarks': remarks,
    if (createdAt != null) 'created_at': createdAt,
  };
}
