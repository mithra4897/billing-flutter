import '../../screen.dart';

class PurchaseReturnLineModel extends JsonModel {
  const PurchaseReturnLineModel({
    super.id,
    this.purchaseReturnId,
    this.purchaseInvoiceLineId,
    this.lineNo,
    this.itemId,
    this.warehouseId,
    this.uomId,
    this.batchId,
    this.serialId,
    this.returnQty,
    this.rate,
    this.discountPercent,
    this.discountAmount,
    this.grossAmount,
    this.taxableAmount,
    this.taxCodeId,
    this.taxPercent,
    this.cgstAmount,
    this.sgstAmount,
    this.igstAmount,
    this.cessAmount,
    this.lineTotal,
    this.returnReason,
    this.remarks,
    this.createdAt,
    this.updatedAt,
  });
  final int? purchaseReturnId;
  final int? purchaseInvoiceLineId;
  final int? lineNo;
  final int? itemId;
  final int? warehouseId;
  final int? uomId;
  final int? batchId;
  final int? serialId;
  final double? returnQty;
  final double? rate;
  final double? discountPercent;
  final double? discountAmount;
  final double? grossAmount;
  final double? taxableAmount;
  final int? taxCodeId;
  final double? taxPercent;
  final double? cgstAmount;
  final double? sgstAmount;
  final double? igstAmount;
  final double? cessAmount;
  final double? lineTotal;
  final String? returnReason;
  final String? remarks;
  final String? createdAt;
  final String? updatedAt;

  factory PurchaseReturnLineModel.fromJson(Map<String, dynamic> json) {
    return PurchaseReturnLineModel(
      id: JsonModel.nullableInt(json['id']),
      purchaseReturnId: JsonModel.nullableInt(json['purchase_return_id']),
      purchaseInvoiceLineId: JsonModel.nullableInt(
        json['purchase_invoice_line_id'],
      ),
      lineNo: JsonModel.nullableInt(json['line_no']),
      itemId: JsonModel.nullableInt(json['item_id']),
      warehouseId: JsonModel.nullableInt(json['warehouse_id']),
      uomId: JsonModel.nullableInt(json['uom_id']),
      batchId: JsonModel.nullableInt(json['batch_id']),
      serialId: JsonModel.nullableInt(json['serial_id']),
      returnQty: JsonModel.nullableDouble(json['return_qty']),
      rate: JsonModel.nullableDouble(json['rate']),
      discountPercent: JsonModel.nullableDouble(json['discount_percent']),
      discountAmount: JsonModel.nullableDouble(json['discount_amount']),
      grossAmount: JsonModel.nullableDouble(json['gross_amount']),
      taxableAmount: JsonModel.nullableDouble(json['taxable_amount']),
      taxCodeId: JsonModel.nullableInt(json['tax_code_id']),
      taxPercent: JsonModel.nullableDouble(json['tax_percent']),
      cgstAmount: JsonModel.nullableDouble(json['cgst_amount']),
      sgstAmount: JsonModel.nullableDouble(json['sgst_amount']),
      igstAmount: JsonModel.nullableDouble(json['igst_amount']),
      cessAmount: JsonModel.nullableDouble(json['cess_amount']),
      lineTotal: JsonModel.nullableDouble(json['line_total']),
      returnReason: json['return_reason']?.toString(),
      remarks: json['remarks']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
  @override
  String toString() => 'Purchase Return Line';


  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (purchaseReturnId != null) 'purchase_return_id': purchaseReturnId,
    if (purchaseInvoiceLineId != null)
      'purchase_invoice_line_id': purchaseInvoiceLineId,
    if (lineNo != null) 'line_no': lineNo,
    if (itemId != null) 'item_id': itemId,
    if (warehouseId != null) 'warehouse_id': warehouseId,
    if (uomId != null) 'uom_id': uomId,
    if (batchId != null) 'batch_id': batchId,
    if (serialId != null) 'serial_id': serialId,
    if (returnQty != null) 'return_qty': returnQty,
    if (rate != null) 'rate': rate,
    if (discountPercent != null) 'discount_percent': discountPercent,
    if (discountAmount != null) 'discount_amount': discountAmount,
    if (grossAmount != null) 'gross_amount': grossAmount,
    if (taxableAmount != null) 'taxable_amount': taxableAmount,
    if (taxCodeId != null) 'tax_code_id': taxCodeId,
    if (taxPercent != null) 'tax_percent': taxPercent,
    if (cgstAmount != null) 'cgst_amount': cgstAmount,
    if (sgstAmount != null) 'sgst_amount': sgstAmount,
    if (igstAmount != null) 'igst_amount': igstAmount,
    if (cessAmount != null) 'cess_amount': cessAmount,
    if (lineTotal != null) 'line_total': lineTotal,
    if (returnReason != null) 'return_reason': returnReason,
    if (remarks != null) 'remarks': remarks,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
