import '../common/json_model.dart';

class JobworkChargeLineModel implements JsonModel {
  const JobworkChargeLineModel({
    this.id,
    this.jobworkChargeId,
    this.lineNo = 1,
    this.serviceDescription = '',
    this.itemId,
    this.outputItemId,
    this.qty = 0,
    this.rate = 0,
    this.amount = 0,
    this.taxCodeId,
    this.taxPercent = 0,
    this.cgstAmount = 0,
    this.sgstAmount = 0,
    this.igstAmount = 0,
    this.cessAmount = 0,
    this.lineTotal = 0,
    this.remarks,
  });

  final int? id;
  final int? jobworkChargeId;
  final int lineNo;
  final String serviceDescription;
  final int? itemId;
  final int? outputItemId;
  final double qty;
  final double rate;
  final double amount;
  final int? taxCodeId;
  final double taxPercent;
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double cessAmount;
  final double lineTotal;
  final String? remarks;

  factory JobworkChargeLineModel.fromJson(Map<String, dynamic> json) {
    return JobworkChargeLineModel(
      id: _i(json['id']),
      jobworkChargeId: _i(json['jobwork_charge_id']),
      lineNo: _i(json['line_no']) ?? 1,
      serviceDescription: json['service_description']?.toString() ?? '',
      itemId: _i(json['item_id']),
      outputItemId: _i(json['output_item_id']),
      qty: _d(json['qty']) ?? 0,
      rate: _d(json['rate']) ?? 0,
      amount: _d(json['amount']) ?? 0,
      taxCodeId: _i(json['tax_code_id']),
      taxPercent: _d(json['tax_percent']) ?? 0,
      cgstAmount: _d(json['cgst_amount']) ?? 0,
      sgstAmount: _d(json['sgst_amount']) ?? 0,
      igstAmount: _d(json['igst_amount']) ?? 0,
      cessAmount: _d(json['cess_amount']) ?? 0,
      lineTotal: _d(json['line_total']) ?? 0,
      remarks: json['remarks']?.toString(),
    );
  }

  Map<String, dynamic> toLinePayload() => <String, dynamic>{
    'service_description': serviceDescription.trim(),
    if (itemId != null) 'item_id': itemId,
    if (outputItemId != null) 'output_item_id': outputItemId,
    'qty': qty,
    'rate': rate,
    'amount': amount,
    if (taxCodeId != null) 'tax_code_id': taxCodeId,
    'tax_percent': taxPercent,
    'cgst_amount': cgstAmount,
    'sgst_amount': sgstAmount,
    'igst_amount': igstAmount,
    'cess_amount': cessAmount,
    'line_total': lineTotal,
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
