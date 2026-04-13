class PurchaseInvoiceLineModel {
  const PurchaseInvoiceLineModel({
    required this.itemId,
    required this.uomId,
    required this.invoicedQty,
    required this.rate,
    this.id,
    this.purchaseOrderLineId,
    this.purchaseReceiptLineId,
    this.warehouseId,
    this.batchId,
    this.serialId,
    this.description,
    this.discountPercent,
    this.taxCodeId,
    this.taxPercent,
    this.taxType,
    this.cessAmount,
    this.remarks,
  });

  final int? id;
  final int? purchaseOrderLineId;
  final int? purchaseReceiptLineId;
  final int itemId;
  final int? warehouseId;
  final int uomId;
  final int? batchId;
  final int? serialId;
  final double invoicedQty;
  final double rate;
  final String? description;
  final double? discountPercent;
  final int? taxCodeId;
  final double? taxPercent;
  final String? taxType;
  final double? cessAmount;
  final String? remarks;

  factory PurchaseInvoiceLineModel.fromJson(Map<String, dynamic> json) {
    return PurchaseInvoiceLineModel(
      id: _nullableInt(json['id']),
      purchaseOrderLineId: _nullableInt(json['purchase_order_line_id']),
      purchaseReceiptLineId: _nullableInt(json['purchase_receipt_line_id']),
      itemId: _parseInt(json['item_id']),
      warehouseId: _nullableInt(json['warehouse_id']),
      uomId: _parseInt(json['uom_id']),
      batchId: _nullableInt(json['batch_id']),
      serialId: _nullableInt(json['serial_id']),
      invoicedQty: _parseDouble(json['invoiced_qty']),
      rate: _parseDouble(json['rate']),
      description: json['description']?.toString(),
      discountPercent: _nullableDouble(json['discount_percent']),
      taxCodeId: _nullableInt(json['tax_code_id']),
      taxPercent: _nullableDouble(json['tax_percent']),
      taxType: json['tax_type']?.toString(),
      cessAmount: _nullableDouble(json['cess_amount']),
      remarks: json['remarks']?.toString(),
    );
  }

  PurchaseInvoiceLineModel copyWith({
    int? id,
    int? purchaseOrderLineId,
    int? purchaseReceiptLineId,
    int? itemId,
    int? warehouseId,
    int? uomId,
    int? batchId,
    int? serialId,
    double? invoicedQty,
    double? rate,
    String? description,
    double? discountPercent,
    int? taxCodeId,
    double? taxPercent,
    String? taxType,
    double? cessAmount,
    String? remarks,
  }) {
    return PurchaseInvoiceLineModel(
      id: id ?? this.id,
      purchaseOrderLineId: purchaseOrderLineId ?? this.purchaseOrderLineId,
      purchaseReceiptLineId:
          purchaseReceiptLineId ?? this.purchaseReceiptLineId,
      itemId: itemId ?? this.itemId,
      warehouseId: warehouseId ?? this.warehouseId,
      uomId: uomId ?? this.uomId,
      batchId: batchId ?? this.batchId,
      serialId: serialId ?? this.serialId,
      invoicedQty: invoicedQty ?? this.invoicedQty,
      rate: rate ?? this.rate,
      description: description ?? this.description,
      discountPercent: discountPercent ?? this.discountPercent,
      taxCodeId: taxCodeId ?? this.taxCodeId,
      taxPercent: taxPercent ?? this.taxPercent,
      taxType: taxType ?? this.taxType,
      cessAmount: cessAmount ?? this.cessAmount,
      remarks: remarks ?? this.remarks,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (purchaseOrderLineId != null)
        'purchase_order_line_id': purchaseOrderLineId,
      if (purchaseReceiptLineId != null)
        'purchase_receipt_line_id': purchaseReceiptLineId,
      'item_id': itemId,
      if (warehouseId != null) 'warehouse_id': warehouseId,
      'uom_id': uomId,
      if (batchId != null) 'batch_id': batchId,
      if (serialId != null) 'serial_id': serialId,
      'invoiced_qty': invoicedQty,
      'rate': rate,
      if (description != null) 'description': description,
      if (discountPercent != null) 'discount_percent': discountPercent,
      if (taxCodeId != null) 'tax_code_id': taxCodeId,
      if (taxPercent != null) 'tax_percent': taxPercent,
      if (taxType != null) 'tax_type': taxType,
      if (cessAmount != null) 'cess_amount': cessAmount,
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
