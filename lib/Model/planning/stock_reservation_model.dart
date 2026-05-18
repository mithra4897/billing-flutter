import '../../screen.dart';

class StockReservationModel implements JsonModel {
  const StockReservationModel({
    this.id,
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

  final int? id;
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
      id: ModelValue.nullableInt(json['id']),
      companyId: ModelValue.nullableInt(json['company_id']),
      itemId: ModelValue.nullableInt(json['item_id']),
      warehouseId: ModelValue.nullableInt(json['warehouse_id']),
      batchId: ModelValue.nullableInt(json['batch_id']),
      serialId: ModelValue.nullableInt(json['serial_id']),
      referenceType: json['reference_type']?.toString(),
      referenceId: ModelValue.nullableInt(json['reference_id']),
      referenceLineId: ModelValue.nullableInt(json['reference_line_id']),
      reservedQty: ModelValue.nullableDouble(json['reserved_qty']),
      releasedQty: ModelValue.nullableDouble(json['released_qty']),
      balanceReservedQty: ModelValue.nullableDouble(
        json['balance_reserved_qty'],
      ),
      status: json['status']?.toString(),
      remarks: json['remarks']?.toString(),
      createdBy: ModelValue.nullableInt(json['created_by']),
      updatedBy: ModelValue.nullableInt(json['updated_by']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

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
