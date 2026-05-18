import '../../screen.dart';

class SalesQuotationLineModel implements JsonModel {
  const SalesQuotationLineModel({
    this.id,
    this.salesQuotationId,
    this.lineNo,
    this.itemId,
    this.warehouseId,
    this.uomId,
    this.description,
    this.qty,
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
    this.remarks,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final int? salesQuotationId;
  final int? lineNo;
  final int? itemId;
  final int? warehouseId;
  final int? uomId;
  final String? description;
  final double? qty;
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
  final String? remarks;
  final String? createdAt;
  final String? updatedAt;

  factory SalesQuotationLineModel.fromJson(Map<String, dynamic> json) {
    return SalesQuotationLineModel(
      id: ModelValue.nullableInt(json['id']),
      salesQuotationId: ModelValue.nullableInt(json['sales_quotation_id']),
      lineNo: ModelValue.nullableInt(json['line_no']),
      itemId: ModelValue.nullableInt(json['item_id']),
      warehouseId: ModelValue.nullableInt(json['warehouse_id']),
      uomId: ModelValue.nullableInt(json['uom_id']),
      description: json['description']?.toString(),
      qty: ModelValue.nullableDouble(json['qty']),
      rate: ModelValue.nullableDouble(json['rate']),
      discountPercent: ModelValue.nullableDouble(json['discount_percent']),
      discountAmount: ModelValue.nullableDouble(json['discount_amount']),
      grossAmount: ModelValue.nullableDouble(json['gross_amount']),
      taxableAmount: ModelValue.nullableDouble(json['taxable_amount']),
      taxCodeId: ModelValue.nullableInt(json['tax_code_id']),
      taxPercent: ModelValue.nullableDouble(json['tax_percent']),
      cgstAmount: ModelValue.nullableDouble(json['cgst_amount']),
      sgstAmount: ModelValue.nullableDouble(json['sgst_amount']),
      igstAmount: ModelValue.nullableDouble(json['igst_amount']),
      cessAmount: ModelValue.nullableDouble(json['cess_amount']),
      lineTotal: ModelValue.nullableDouble(json['line_total']),
      remarks: json['remarks']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (salesQuotationId != null) 'sales_quotation_id': salesQuotationId,
    if (lineNo != null) 'line_no': lineNo,
    if (itemId != null) 'item_id': itemId,
    if (warehouseId != null) 'warehouse_id': warehouseId,
    if (uomId != null) 'uom_id': uomId,
    if (description != null) 'description': description,
    if (qty != null) 'qty': qty,
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
    if (remarks != null) 'remarks': remarks,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
