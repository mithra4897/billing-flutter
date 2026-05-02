import '../common/json_model.dart';

/// Output line on a jobwork order (`jobwork_order_outputs`).
class JobworkOrderOutputModel implements JsonModel {
  const JobworkOrderOutputModel({
    this.id,
    this.jobworkOrderId,
    this.lineNo = 1,
    this.itemId,
    this.uomId,
    this.outputType = 'processed_material',
    this.plannedQty = 0,
    this.receivedQty = 0,
    this.rejectedQty = 0,
    this.acceptedQty = 0,
    this.standardRate = 0,
    this.standardAmount = 0,
    this.remarks,
  });

  final int? id;
  final int? jobworkOrderId;
  final int lineNo;
  final int? itemId;
  final int? uomId;
  final String outputType;
  final double plannedQty;
  final double receivedQty;
  final double rejectedQty;
  final double acceptedQty;
  final double standardRate;
  final double standardAmount;
  final String? remarks;

  factory JobworkOrderOutputModel.fromJson(Map<String, dynamic> json) {
    return JobworkOrderOutputModel(
      id: _parseInt(json['id']),
      jobworkOrderId: _parseInt(json['jobwork_order_id']),
      lineNo: _parseInt(json['line_no']) ?? 1,
      itemId: _parseInt(json['item_id']),
      uomId: _parseInt(json['uom_id']),
      outputType: json['output_type']?.toString() ?? 'processed_material',
      plannedQty: _parseDouble(json['planned_qty']) ?? 0,
      receivedQty: _parseDouble(json['received_qty']) ?? 0,
      rejectedQty: _parseDouble(json['rejected_qty']) ?? 0,
      acceptedQty: _parseDouble(json['accepted_qty']) ?? 0,
      standardRate: _parseDouble(json['standard_rate']) ?? 0,
      standardAmount: _parseDouble(json['standard_amount']) ?? 0,
      remarks: json['remarks']?.toString(),
    );
  }

  Map<String, dynamic> toLinePayload() => <String, dynamic>{
    'item_id': itemId,
    'uom_id': uomId,
    'output_type': outputType,
    'planned_qty': plannedQty,
    'received_qty': receivedQty,
    'rejected_qty': rejectedQty,
    'accepted_qty': acceptedQty,
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
