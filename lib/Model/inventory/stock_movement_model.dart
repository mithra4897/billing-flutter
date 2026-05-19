import '../../screen.dart';

class StockMovementModel extends JsonModel {
  const StockMovementModel({
    super.id,
    this.companyId,
    this.branchId,
    this.locationId,
    this.financialYearId,
    this.movementDate,
    this.itemId,
    this.warehouseId,
    this.batchId,
    this.serialId,
    this.uomId,
    this.movementType,
    this.referenceModule,
    this.referenceTable,
    this.referenceId,
    this.referenceLineId,
    this.referenceNo,
    this.qtyIn,
    this.qtyOut,
    this.unitCost,
    this.totalCost,
    this.rate,
    this.amount,
    this.sourceWarehouseId,
    this.destinationWarehouseId,
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
  final int? itemId;
  final int? warehouseId;
  final int? batchId;
  final int? serialId;
  final int? uomId;
  final String? movementType;
  final String? referenceModule;
  final String? referenceTable;
  final int? referenceId;
  final int? referenceLineId;
  final String? referenceNo;
  final double? qtyIn;
  final double? qtyOut;
  final double? unitCost;
  final double? totalCost;
  final double? rate;
  final double? amount;
  final int? sourceWarehouseId;
  final int? destinationWarehouseId;
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
      id: ModelValue.nullableInt(json['id']),
      companyId: ModelValue.nullableInt(json['company_id']),
      branchId: ModelValue.nullableInt(json['branch_id']),
      locationId: ModelValue.nullableInt(json['location_id']),
      financialYearId: ModelValue.nullableInt(json['financial_year_id']),
      movementDate: json['movement_date']?.toString(),
      itemId: ModelValue.nullableInt(json['item_id']),
      warehouseId: ModelValue.nullableInt(json['warehouse_id']),
      batchId: ModelValue.nullableInt(json['batch_id']),
      serialId: ModelValue.nullableInt(json['serial_id']),
      uomId: ModelValue.nullableInt(json['uom_id']),
      movementType: json['movement_type']?.toString(),
      referenceModule: json['reference_module']?.toString(),
      referenceTable: json['reference_table']?.toString(),
      referenceId: ModelValue.nullableInt(json['reference_id']),
      referenceLineId: ModelValue.nullableInt(json['reference_line_id']),
      referenceNo: json['reference_no']?.toString(),
      qtyIn: ModelValue.nullableDouble(json['qty_in']),
      qtyOut: ModelValue.nullableDouble(json['qty_out']),
      unitCost: ModelValue.nullableDouble(json['unit_cost']),
      totalCost: ModelValue.nullableDouble(json['total_cost']),
      rate: ModelValue.nullableDouble(json['rate']),
      amount: ModelValue.nullableDouble(json['amount']),
      sourceWarehouseId: ModelValue.nullableInt(json['source_warehouse_id']),
      destinationWarehouseId: ModelValue.nullableInt(
        json['destination_warehouse_id'],
      ),
      lineNarration: json['line_narration']?.toString(),
      postedBy: ModelValue.nullableInt(json['posted_by']),
      postedAt: json['posted_at']?.toString(),
      isCancelled: json['is_cancelled'] == null
          ? null
          : ModelValue.boolOf(json['is_cancelled']),
      cancelledBy: ModelValue.nullableInt(json['cancelled_by']),
      cancelledAt: json['cancelled_at']?.toString(),
      createdBy: ModelValue.nullableInt(json['created_by']),
      updatedBy: ModelValue.nullableInt(json['updated_by']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
  @override
  String toString() => 'Stock Movement';


  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (companyId != null) 'company_id': companyId,
    if (branchId != null) 'branch_id': branchId,
    if (locationId != null) 'location_id': locationId,
    if (financialYearId != null) 'financial_year_id': financialYearId,
    if (movementDate != null) 'movement_date': movementDate,
    if (itemId != null) 'item_id': itemId,
    if (warehouseId != null) 'warehouse_id': warehouseId,
    if (batchId != null) 'batch_id': batchId,
    if (serialId != null) 'serial_id': serialId,
    if (uomId != null) 'uom_id': uomId,
    if (movementType != null) 'movement_type': movementType,
    if (referenceModule != null) 'reference_module': referenceModule,
    if (referenceTable != null) 'reference_table': referenceTable,
    if (referenceId != null) 'reference_id': referenceId,
    if (referenceLineId != null) 'reference_line_id': referenceLineId,
    if (referenceNo != null) 'reference_no': referenceNo,
    if (qtyIn != null) 'qty_in': qtyIn,
    if (qtyOut != null) 'qty_out': qtyOut,
    if (unitCost != null) 'unit_cost': unitCost,
    if (totalCost != null) 'total_cost': totalCost,
    if (rate != null) 'rate': rate,
    if (amount != null) 'amount': amount,
    if (sourceWarehouseId != null) 'source_warehouse_id': sourceWarehouseId,
    if (destinationWarehouseId != null)
      'destination_warehouse_id': destinationWarehouseId,
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
