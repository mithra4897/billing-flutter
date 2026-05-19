import '../../screen.dart';

class StockSerialModel extends JsonModel {
  const StockSerialModel({
    super.id,
    this.itemId,
    this.warehouseId,
    this.batchId,
    this.serialNo,
    this.status,
    this.inwardDate,
    this.outwardDate,
    this.remarks,
    this.createdAt,
    this.updatedAt,
  });
  final int? itemId;
  final int? warehouseId;
  final int? batchId;
  final String? serialNo;
  final String? status;
  final String? inwardDate;
  final String? outwardDate;
  final String? remarks;
  final String? createdAt;
  final String? updatedAt;

  factory StockSerialModel.fromJson(Map<String, dynamic> json) {
    return StockSerialModel(
      id: JsonModel.nullableInt(json['id']),
      itemId: JsonModel.nullableInt(json['item_id']),
      warehouseId: JsonModel.nullableInt(json['warehouse_id']),
      batchId: JsonModel.nullableInt(json['batch_id']),
      serialNo: json['serial_no']?.toString(),
      status: json['status']?.toString(),
      inwardDate: json['inward_date']?.toString(),
      outwardDate: json['outward_date']?.toString(),
      remarks: json['remarks']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
  @override
  String toString() => JsonModel.combineValues([
    serialNo,
    inwardDate,
    outwardDate,
  ], defaultValue: 'Stock Serial');


  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (itemId != null) 'item_id': itemId,
    if (warehouseId != null) 'warehouse_id': warehouseId,
    if (batchId != null) 'batch_id': batchId,
    if (serialNo != null) 'serial_no': serialNo,
    if (status != null) 'status': status,
    if (inwardDate != null) 'inward_date': inwardDate,
    if (outwardDate != null) 'outward_date': outwardDate,
    if (remarks != null) 'remarks': remarks,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
