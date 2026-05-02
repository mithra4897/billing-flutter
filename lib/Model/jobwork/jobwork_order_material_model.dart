import '../common/json_model.dart';

/// Material line on a jobwork order (`jobwork_order_materials`).
class JobworkOrderMaterialModel implements JsonModel {
  const JobworkOrderMaterialModel({
    this.id,
    this.jobworkOrderId,
    this.lineNo = 1,
    this.itemId,
    this.uomId,
    this.lineType = 'raw_material',
    this.plannedQty = 0,
    this.dispatchedQty = 0,
    this.receivedBackQty = 0,
    this.consumedQty = 0,
    this.pendingWithVendorQty = 0,
    this.standardRate = 0,
    this.standardAmount = 0,
    this.remarks,
  });

  final int? id;
  final int? jobworkOrderId;
  final int lineNo;
  final int? itemId;
  final int? uomId;
  final String lineType;
  final double plannedQty;
  final double dispatchedQty;
  final double receivedBackQty;
  final double consumedQty;
  final double pendingWithVendorQty;
  final double standardRate;
  final double standardAmount;
  final String? remarks;

  factory JobworkOrderMaterialModel.fromJson(Map<String, dynamic> json) {
    return JobworkOrderMaterialModel(
      id: _parseInt(json['id']),
      jobworkOrderId: _parseInt(json['jobwork_order_id']),
      lineNo: _parseInt(json['line_no']) ?? 1,
      itemId: _parseInt(json['item_id']),
      uomId: _parseInt(json['uom_id']),
      lineType: json['line_type']?.toString() ?? 'raw_material',
      plannedQty: _parseDouble(json['planned_qty']) ?? 0,
      dispatchedQty: _parseDouble(json['dispatched_qty']) ?? 0,
      receivedBackQty: _parseDouble(json['received_back_qty']) ?? 0,
      consumedQty: _parseDouble(json['consumed_qty']) ?? 0,
      pendingWithVendorQty: _parseDouble(json['pending_with_vendor_qty']) ?? 0,
      standardRate: _parseDouble(json['standard_rate']) ?? 0,
      standardAmount: _parseDouble(json['standard_amount']) ?? 0,
      remarks: json['remarks']?.toString(),
    );
  }

  /// Payload for create/update `materials[]` on the jobwork order API.
  Map<String, dynamic> toLinePayload() => <String, dynamic>{
    'item_id': itemId,
    'uom_id': uomId,
    'line_type': lineType,
    'planned_qty': plannedQty,
    'dispatched_qty': dispatchedQty,
    'received_back_qty': receivedBackQty,
    'consumed_qty': consumedQty,
    'pending_with_vendor_qty': pendingWithVendorQty,
    'standard_rate': standardRate,
    'standard_amount': standardAmount,
    'remarks': remarks,
  };

  @override
  Map<String, dynamic> toJson() => toLinePayload();

  static int? _parseInt(dynamic v) {
    if (v == null) {
      return null;
    }
    if (v is int) {
      return v;
    }
    return int.tryParse(v.toString());
  }

  static double? _parseDouble(dynamic v) {
    if (v == null) {
      return null;
    }
    if (v is num) {
      return v.toDouble();
    }
    return double.tryParse(v.toString());
  }
}
