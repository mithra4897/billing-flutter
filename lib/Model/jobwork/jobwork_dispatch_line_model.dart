import '../common/json_model.dart';

class JobworkDispatchLineModel implements JsonModel {
  const JobworkDispatchLineModel({
    this.id,
    this.jobworkDispatchId,
    this.jobworkOrderMaterialId,
    this.lineNo = 1,
    this.itemId,
    this.uomId,
    this.warehouseId,
    this.batchId,
    this.serialId,
    this.dispatchQty = 0,
    this.unitCost = 0,
    this.totalCost = 0,
    this.remarks,
  });

  final int? id;
  final int? jobworkDispatchId;
  final int? jobworkOrderMaterialId;
  final int lineNo;
  final int? itemId;
  final int? uomId;
  final int? warehouseId;
  final int? batchId;
  final int? serialId;
  final double dispatchQty;
  final double unitCost;
  final double totalCost;
  final String? remarks;

  factory JobworkDispatchLineModel.fromJson(Map<String, dynamic> json) {
    return JobworkDispatchLineModel(
      id: _i(json['id']),
      jobworkDispatchId: _i(json['jobwork_dispatch_id']),
      jobworkOrderMaterialId: _i(json['jobwork_order_material_id']),
      lineNo: _i(json['line_no']) ?? 1,
      itemId: _i(json['item_id']),
      uomId: _i(json['uom_id']),
      warehouseId: _i(json['warehouse_id']),
      batchId: _i(json['batch_id']),
      serialId: _i(json['serial_id']),
      dispatchQty: _d(json['dispatch_qty']) ?? 0,
      unitCost: _d(json['unit_cost']) ?? 0,
      totalCost: _d(json['total_cost']) ?? 0,
      remarks: json['remarks']?.toString(),
    );
  }

  Map<String, dynamic> toLinePayload() => <String, dynamic>{
    if (jobworkOrderMaterialId != null)
      'jobwork_order_material_id': jobworkOrderMaterialId,
    'item_id': itemId,
    'uom_id': uomId,
    'warehouse_id': warehouseId,
    if (batchId != null) 'batch_id': batchId,
    if (serialId != null) 'serial_id': serialId,
    'dispatch_qty': dispatchQty,
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
