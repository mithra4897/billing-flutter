class SalesInvoiceLineModel {
  const SalesInvoiceLineModel({
    required this.itemId,
    required this.uomId,
    required this.invoicedQty,
    required this.rate,
    this.id,
    this.warehouseId,
    this.description,
    this.discountPercent,
    this.taxCodeId,
    this.taxPercent,
    this.taxType,
    this.taxableAmount,
    this.lineTotal,
    this.remarks,
    this.returnedQty,
    this.salesOrderLineId,
    this.salesDeliveryLineId,
    this.serialId,
    this.serialNo,
  });

  final int? id;
  final int? salesOrderLineId;
  final int? salesDeliveryLineId;
  final int itemId;
  final int? warehouseId;
  final int? serialId;
  final String? serialNo;
  final int uomId;
  final double invoicedQty;
  final double rate;
  final String? description;
  final double? discountPercent;
  final int? taxCodeId;
  final double? taxPercent;
  final String? taxType;
  final double? taxableAmount;
  final double? lineTotal;
  final String? remarks;
  final double? returnedQty;

  factory SalesInvoiceLineModel.fromJson(Map<String, dynamic> json) {
    return SalesInvoiceLineModel(
      id: _nullableInt(json['id']),
      salesOrderLineId: _nullableInt(json['sales_order_line_id']),
      salesDeliveryLineId: _nullableInt(json['sales_delivery_line_id']),
      itemId: _parseInt(json['item_id']),
      warehouseId: _nullableInt(json['warehouse_id']),
      serialId: _nullableInt(json['serial_id']),
      serialNo: json['serial_no']?.toString() ??
          (json['serial'] is Map
              ? (json['serial']['serial_no']?.toString())
              : null),
      uomId: _parseInt(json['uom_id']),
      invoicedQty: _parseDouble(json['invoiced_qty']),
      rate: _parseDouble(json['rate']),
      description: json['description']?.toString(),
      discountPercent: _nullableDouble(json['discount_percent']),
      taxCodeId: _nullableInt(json['tax_code_id']),
      taxPercent: _nullableDouble(json['tax_percent']),
      taxType: json['tax_type']?.toString(),
      taxableAmount: _nullableDouble(json['taxable_amount']),
      lineTotal: _nullableDouble(json['line_total']),
      remarks: json['remarks']?.toString(),
      returnedQty: _nullableDouble(json['returned_qty']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (salesOrderLineId != null) 'sales_order_line_id': salesOrderLineId,
      if (salesDeliveryLineId != null)
        'sales_delivery_line_id': salesDeliveryLineId,
      'item_id': itemId,
      if (warehouseId != null) 'warehouse_id': warehouseId,
      if (serialId != null) 'serial_id': serialId,
      if (serialNo != null && serialNo!.trim().isNotEmpty)
        'serial_no': serialNo!.trim(),
      'uom_id': uomId,
      'invoiced_qty': invoicedQty,
      'rate': rate,
      if (description != null) 'description': description,
      if (discountPercent != null) 'discount_percent': discountPercent,
      if (taxCodeId != null) 'tax_code_id': taxCodeId,
      if (taxPercent != null) 'tax_percent': taxPercent,
      if (taxType != null) 'tax_type': taxType,
      if (remarks != null) 'remarks': remarks,
    };
  }

  static int _parseInt(dynamic value) =>
      int.tryParse(value?.toString() ?? '') ?? 0;

  static int? _nullableInt(dynamic value) =>
      int.tryParse(value?.toString() ?? '');

  static double _parseDouble(dynamic value) =>
      double.tryParse(value?.toString() ?? '') ?? 0;

  static double? _nullableDouble(dynamic value) =>
      double.tryParse(value?.toString() ?? '');
}
