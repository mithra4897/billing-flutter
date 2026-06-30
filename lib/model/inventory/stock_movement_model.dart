import '../../screen.dart';

class StockMovementModel extends JsonModel {
  const StockMovementModel({
    super.id,
    this.companyId,
    this.branchId,
    this.locationId,
    this.financialYearId,
    this.movementDate,
    this.voucherDate,
    this.itemId,
    this.warehouseId,
    this.batchId,
    this.serialId,
    this.uomId,
    this.movementType,
    this.stockEffect,
    this.referenceType,
    this.referenceModule,
    this.referenceTable,
    this.referenceId,
    this.referenceLineId,
    this.referenceNo,
    this.qty,
    this.qtyIn,
    this.qtyOut,
    this.unitCost,
    this.totalCost,
    this.rate,
    this.amount,
    this.sourceWarehouseId,
    this.destinationWarehouseId,
    this.remarks,
    this.lineNarration,
    this.postedBy,
    this.postedAt,
    this.isCancelled,
    this.cancelledBy,
    this.cancelledAt,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  });
  final int? companyId;
  final int? branchId;
  final int? locationId;
  final int? financialYearId;
  final String? movementDate;
  final String? voucherDate;
  final int? itemId;
  final int? warehouseId;
  final int? batchId;
  final int? serialId;
  final int? uomId;
  final String? movementType;
  final String? stockEffect;
  final String? referenceType;
  final String? referenceModule;
  final String? referenceTable;
  final int? referenceId;
  final int? referenceLineId;
  final String? referenceNo;
  final double? qty;
  final double? qtyIn;
  final double? qtyOut;
  final double? unitCost;
  final double? totalCost;
  final double? rate;
  final double? amount;
  final int? sourceWarehouseId;
  final int? destinationWarehouseId;
  final String? remarks;
  final String? lineNarration;
  final int? postedBy;
  final String? postedAt;
  final bool? isCancelled;
  final int? cancelledBy;
  final String? cancelledAt;
  final int? createdBy;
  final int? updatedBy;
  final String? createdAt;
  final String? updatedAt;

  factory StockMovementModel.fromJson(Map<String, dynamic> json) {
    return StockMovementModel(
      id: JsonModel.nullableInt(json['id']),
      companyId: JsonModel.nullableInt(json['company_id']),
      branchId: JsonModel.nullableInt(json['branch_id']),
      locationId: JsonModel.nullableInt(json['location_id']),
      financialYearId: JsonModel.nullableInt(json['financial_year_id']),
      movementDate: json['movement_date']?.toString(),
      voucherDate:
          json['voucher_date']?.toString() ?? json['movement_date']?.toString(),
      itemId: JsonModel.nullableInt(json['item_id']),
      warehouseId: JsonModel.nullableInt(json['warehouse_id']),
      batchId: JsonModel.nullableInt(json['batch_id']),
      serialId: JsonModel.nullableInt(json['serial_id']),
      uomId: JsonModel.nullableInt(json['uom_id']),
      movementType: json['movement_type']?.toString(),
      stockEffect: json['stock_effect']?.toString(),
      referenceType:
          json['reference_type']?.toString() ??
          json['reference_module']?.toString(),
      referenceModule: json['reference_module']?.toString(),
      referenceTable: json['reference_table']?.toString(),
      referenceId: JsonModel.nullableInt(json['reference_id']),
      referenceLineId: JsonModel.nullableInt(json['reference_line_id']),
      referenceNo: json['reference_no']?.toString(),
      qty:
          JsonModel.nullableDouble(json['qty']) ??
          JsonModel.nullableDouble(json['qty_in']) ??
          JsonModel.nullableDouble(json['qty_out']),
      qtyIn: JsonModel.nullableDouble(json['qty_in']),
      qtyOut: JsonModel.nullableDouble(json['qty_out']),
      unitCost: JsonModel.nullableDouble(json['unit_cost']),
      totalCost: JsonModel.nullableDouble(json['total_cost']),
      rate: JsonModel.nullableDouble(json['rate']),
      amount: JsonModel.nullableDouble(json['amount']),
      sourceWarehouseId: JsonModel.nullableInt(json['source_warehouse_id']),
      destinationWarehouseId: JsonModel.nullableInt(
        json['destination_warehouse_id'],
      ),
      remarks:
          json['remarks']?.toString() ?? json['line_narration']?.toString(),
      lineNarration: json['line_narration']?.toString(),
      postedBy: JsonModel.nullableInt(json['posted_by']),
      postedAt: json['posted_at']?.toString(),
      isCancelled: json['is_cancelled'] == null
          ? null
          : JsonModel.boolOf(json['is_cancelled']),
      cancelledBy: JsonModel.nullableInt(json['cancelled_by']),
      cancelledAt: json['cancelled_at']?.toString(),
      createdBy: JsonModel.nullableInt(json['created_by']),
      updatedBy: JsonModel.nullableInt(json['updated_by']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
  @override
  String toString() => JsonModel.combineValues([
    referenceNo,
    movementDate,
    movementType,
  ], defaultValue: 'Stock Movement');

  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (companyId != null) 'company_id': companyId,
    if (branchId != null) 'branch_id': branchId,
    if (locationId != null) 'location_id': locationId,
    if (financialYearId != null) 'financial_year_id': financialYearId,
    if (movementDate != null) 'movement_date': movementDate,
    if (voucherDate != null) 'voucher_date': voucherDate,
    if (itemId != null) 'item_id': itemId,
    if (warehouseId != null) 'warehouse_id': warehouseId,
    if (batchId != null) 'batch_id': batchId,
    if (serialId != null) 'serial_id': serialId,
    if (uomId != null) 'uom_id': uomId,
    if (movementType != null) 'movement_type': movementType,
    if (stockEffect != null) 'stock_effect': stockEffect,
    if (referenceType != null) 'reference_type': referenceType,
    if (referenceModule != null) 'reference_module': referenceModule,
    if (referenceTable != null) 'reference_table': referenceTable,
    if (referenceId != null) 'reference_id': referenceId,
    if (referenceLineId != null) 'reference_line_id': referenceLineId,
    if (referenceNo != null) 'reference_no': referenceNo,
    if (qty != null) 'qty': qty,
    if (qtyIn != null) 'qty_in': qtyIn,
    if (qtyOut != null) 'qty_out': qtyOut,
    if (unitCost != null) 'unit_cost': unitCost,
    if (totalCost != null) 'total_cost': totalCost,
    if (rate != null) 'rate': rate,
    if (amount != null) 'amount': amount,
    if (sourceWarehouseId != null) 'source_warehouse_id': sourceWarehouseId,
    if (destinationWarehouseId != null)
      'destination_warehouse_id': destinationWarehouseId,
    if (remarks != null) 'remarks': remarks,
    if (lineNarration != null) 'line_narration': lineNarration,
    if (postedBy != null) 'posted_by': postedBy,
    if (postedAt != null) 'posted_at': postedAt,
    if (isCancelled != null) 'is_cancelled': isCancelled,
    if (cancelledBy != null) 'cancelled_by': cancelledBy,
    if (cancelledAt != null) 'cancelled_at': cancelledAt,
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
