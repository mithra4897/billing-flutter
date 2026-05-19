import '../../screen.dart';

class StockReservationModel extends JsonModel {
  const StockReservationModel({
    super.id,
    this.companyId,
    this.itemId,
    this.warehouseId,
    this.batchId,
    this.serialId,
    this.referenceType,
    this.referenceId,
    this.referenceLineId,
    this.reservedQty,
    this.releasedQty,
    this.balanceReservedQty,
    this.status,
    this.remarks,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  });
  final int? companyId;
  final int? itemId;
  final int? warehouseId;
  final int? batchId;
  final int? serialId;
  final String? referenceType;
  final int? referenceId;
  final int? referenceLineId;
  final double? reservedQty;
  final double? releasedQty;
  final double? balanceReservedQty;
  final String? status;
  final String? remarks;
  final int? createdBy;
  final int? updatedBy;
  final String? createdAt;
  final String? updatedAt;

  factory StockReservationModel.fromJson(Map<String, dynamic> json) {
    return StockReservationModel(
      id: JsonModel.nullableInt(json['id']),
      companyId: JsonModel.nullableInt(json['company_id']),
      itemId: JsonModel.nullableInt(json['item_id']),
      warehouseId: JsonModel.nullableInt(json['warehouse_id']),
      batchId: JsonModel.nullableInt(json['batch_id']),
      serialId: JsonModel.nullableInt(json['serial_id']),
      referenceType: json['reference_type']?.toString(),
      referenceId: JsonModel.nullableInt(json['reference_id']),
      referenceLineId: JsonModel.nullableInt(json['reference_line_id']),
      reservedQty: JsonModel.nullableDouble(json['reserved_qty']),
      releasedQty: JsonModel.nullableDouble(json['released_qty']),
      balanceReservedQty: JsonModel.nullableDouble(
        json['balance_reserved_qty'],
      ),
      status: json['status']?.toString(),
      remarks: json['remarks']?.toString(),
      createdBy: JsonModel.nullableInt(json['created_by']),
      updatedBy: JsonModel.nullableInt(json['updated_by']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
  @override
  String toString() => 'Stock Reservation';


  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (companyId != null) 'company_id': companyId,
    if (itemId != null) 'item_id': itemId,
    if (warehouseId != null) 'warehouse_id': warehouseId,
    if (batchId != null) 'batch_id': batchId,
    if (serialId != null) 'serial_id': serialId,
    if (referenceType != null) 'reference_type': referenceType,
    if (referenceId != null) 'reference_id': referenceId,
    if (referenceLineId != null) 'reference_line_id': referenceLineId,
    if (reservedQty != null) 'reserved_qty': reservedQty,
    if (releasedQty != null) 'released_qty': releasedQty,
    if (balanceReservedQty != null) 'balance_reserved_qty': balanceReservedQty,
    if (status != null) 'status': status,
    if (remarks != null) 'remarks': remarks,
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
