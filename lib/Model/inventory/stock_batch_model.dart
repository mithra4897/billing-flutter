import '../../screen.dart';

class StockBatchModel implements JsonModel {
  const StockBatchModel({
    this.id,
    this.itemId,
    this.warehouseId,
    this.batchNo,
    this.mfgDate,
    this.manufactureDate,
    this.expiryDate,
    this.inwardQty,
    this.outwardQty,
    this.balanceQty,
    this.qtyAvailable,
    this.purchaseRate,
    this.salesRate,
    this.mrp,
    this.isActive,
    this.status,
    this.remarks,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final int? itemId;
  final int? warehouseId;
  final String? batchNo;
  final String? mfgDate;
  final String? manufactureDate;
  final String? expiryDate;
  final double? inwardQty;
  final double? outwardQty;
  final double? balanceQty;
  final double? qtyAvailable;
  final double? purchaseRate;
  final double? salesRate;
  final double? mrp;
  final bool? isActive;
  final String? status;
  final String? remarks;
  final int? createdBy;
  final int? updatedBy;
  final String? createdAt;
  final String? updatedAt;

  factory StockBatchModel.fromJson(Map<String, dynamic> json) {
    return StockBatchModel(
      id: ModelValue.nullableInt(json['id']),
      itemId: ModelValue.nullableInt(json['item_id']),
      warehouseId: ModelValue.nullableInt(json['warehouse_id']),
      batchNo: json['batch_no']?.toString(),
      mfgDate: json['mfg_date']?.toString(),
      manufactureDate: json['manufacture_date']?.toString(),
      expiryDate: json['expiry_date']?.toString(),
      inwardQty: ModelValue.nullableDouble(json['inward_qty']),
      outwardQty: ModelValue.nullableDouble(json['outward_qty']),
      balanceQty: ModelValue.nullableDouble(json['balance_qty']),
      qtyAvailable: ModelValue.nullableDouble(json['qty_available']),
      purchaseRate: ModelValue.nullableDouble(json['purchase_rate']),
      salesRate: ModelValue.nullableDouble(json['sales_rate']),
      mrp: ModelValue.nullableDouble(json['mrp']),
      isActive: json['is_active'] == null
          ? null
          : ModelValue.boolOf(json['is_active']),
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
    if (itemId != null) 'item_id': itemId,
    if (warehouseId != null) 'warehouse_id': warehouseId,
    if (batchNo != null) 'batch_no': batchNo,
    if (mfgDate != null) 'mfg_date': mfgDate,
    if (manufactureDate != null) 'manufacture_date': manufactureDate,
    if (expiryDate != null) 'expiry_date': expiryDate,
    if (inwardQty != null) 'inward_qty': inwardQty,
    if (outwardQty != null) 'outward_qty': outwardQty,
    if (balanceQty != null) 'balance_qty': balanceQty,
    if (qtyAvailable != null) 'qty_available': qtyAvailable,
    if (purchaseRate != null) 'purchase_rate': purchaseRate,
    if (salesRate != null) 'sales_rate': salesRate,
    if (mrp != null) 'mrp': mrp,
    if (isActive != null) 'is_active': isActive,
    if (status != null) 'status': status,
    if (remarks != null) 'remarks': remarks,
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
