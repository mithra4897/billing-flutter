import '../common/json_model.dart';

class JobworkReceiptLineModel implements JsonModel {
  const JobworkReceiptLineModel({
    this.id,
    this.jobworkReceiptId,
    this.jobworkOrderOutputId,
    this.lineNo = 1,
    this.itemId,
    this.uomId,
    this.warehouseId,
    this.batchId,
    this.serialId,
    this.receiptQty = 0,
    this.acceptedQty = 0,
    this.rejectedQty = 0,
    this.outputType = 'processed_material',
    this.unitCost = 0,
    this.totalCost = 0,
    this.remarks,
  });

  final int? id;
  final int? jobworkReceiptId;
  final int? jobworkOrderOutputId;
  final int lineNo;
  final int? itemId;
  final int? uomId;
  final int? warehouseId;
  final int? batchId;
  final int? serialId;
  final double receiptQty;
  final double acceptedQty;
  final double rejectedQty;
  final String outputType;
  final double unitCost;
  final double totalCost;
  final String? remarks;

  factory JobworkReceiptLineModel.fromJson(Map<String, dynamic> json) {
    return JobworkReceiptLineModel(
      id: _i(json['id']),
      jobworkReceiptId: _i(json['jobwork_receipt_id']),
      jobworkOrderOutputId: _i(json['jobwork_order_output_id']),
      lineNo: _i(json['line_no']) ?? 1,
      itemId: _i(json['item_id']),
      uomId: _i(json['uom_id']),
      warehouseId: _i(json['warehouse_id']),
      batchId: _i(json['batch_id']),
      serialId: _i(json['serial_id']),
      receiptQty: _d(json['receipt_qty']) ?? 0,
      acceptedQty: _d(json['accepted_qty']) ?? 0,
      rejectedQty: _d(json['rejected_qty']) ?? 0,
      outputType: json['output_type']?.toString() ?? 'processed_material',
      unitCost: _d(json['unit_cost']) ?? 0,
      totalCost: _d(json['total_cost']) ?? 0,
      remarks: json['remarks']?.toString(),
    );
  }

  Map<String, dynamic> toLinePayload() => <String, dynamic>{
    if (jobworkOrderOutputId != null)
      'jobwork_order_output_id': jobworkOrderOutputId,
    'item_id': itemId,
    'uom_id': uomId,
    'warehouse_id': warehouseId,
    if (batchId != null) 'batch_id': batchId,
    if (serialId != null) 'serial_id': serialId,
    'receipt_qty': receiptQty,
    'accepted_qty': acceptedQty,
    'rejected_qty': rejectedQty,
    'output_type': outputType,
    'unit_cost': unitCost,
    'total_cost': totalCost,
    'remarks': remarks,
  };

  @override
  Map<String, dynamic> toJson() => toLinePayload();

  static int? _i(dynamic v) {
    if (v == null) {
      return null;
    }
    if (v is int) {
      return v;
    }
    return int.tryParse(v.toString());
  }

  static double? _d(dynamic v) {
    if (v == null) {
      return null;
    }
    if (v is num) {
      return v.toDouble();
    }
    return double.tryParse(v.toString());
  }
}
