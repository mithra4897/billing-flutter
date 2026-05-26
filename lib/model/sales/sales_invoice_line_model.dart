import '../../screen.dart';

class SalesInvoiceLineModel extends JsonModel {
  const SalesInvoiceLineModel({
    required this.itemId,
    required this.uomId,
    required this.invoicedQty,
    required this.rate,
    super.id,
    this.warehouseId,
    this.batchId,
    this.batchNo,
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
  final int? salesOrderLineId;
  final int? salesDeliveryLineId;
  final int itemId;
  final int? warehouseId;
  final int? batchId;
  final String? batchNo;
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
    final itemJson = json['item'] is Map<String, dynamic>
        ? json['item'] as Map<String, dynamic>
        : null;
    final warehouseJson = json['warehouse'] is Map<String, dynamic>
        ? json['warehouse'] as Map<String, dynamic>
        : null;
    final batchJson = json['batch'] is Map<String, dynamic>
        ? json['batch'] as Map<String, dynamic>
        : null;
    final serialJson = json['serial'] is Map<String, dynamic>
        ? json['serial'] as Map<String, dynamic>
        : null;
    final uomJson = json['uom'] is Map<String, dynamic>
        ? json['uom'] as Map<String, dynamic>
        : null;
    final taxCodeJson = json['tax_code'] is Map<String, dynamic>
        ? json['tax_code'] as Map<String, dynamic>
        : (json['taxCode'] is Map<String, dynamic>
              ? json['taxCode'] as Map<String, dynamic>
              : null);
    return SalesInvoiceLineModel(
      id: _nullableInt(json['id']),
      salesOrderLineId: _nullableInt(json['sales_order_line_id']),
      salesDeliveryLineId: _nullableInt(json['sales_delivery_line_id']),
      itemId: _nullableInt(json['item_id']) ?? _parseInt(itemJson?['id']),
      warehouseId:
          _nullableInt(json['warehouse_id']) ??
          _nullableInt(warehouseJson?['id']),
      batchId: _nullableInt(json['batch_id']) ?? _nullableInt(batchJson?['id']),
      batchNo:
          json['batch_no']?.toString() ?? batchJson?['batch_no']?.toString(),
      serialId:
          _nullableInt(json['serial_id']) ?? _nullableInt(serialJson?['id']),
      serialNo:
          json['serial_no']?.toString() ?? serialJson?['serial_no']?.toString(),
      uomId: _nullableInt(json['uom_id']) ?? _parseInt(uomJson?['id']),
      invoicedQty: _parseDouble(json['invoiced_qty']),
      rate: _parseDouble(json['rate']),
      description: json['description']?.toString(),
      discountPercent: _nullableDouble(json['discount_percent']),
      taxCodeId:
          _nullableInt(json['tax_code_id']) ?? _nullableInt(taxCodeJson?['id']),
      taxPercent: _nullableDouble(json['tax_percent']),
      taxType: json['tax_type']?.toString(),
      taxableAmount: _nullableDouble(json['taxable_amount']),
      lineTotal: _nullableDouble(json['line_total']),
      remarks: json['remarks']?.toString(),
      returnedQty: _nullableDouble(json['returned_qty']),
    );
  }
  @override
  String toString() => description ?? 'Sales Invoice Line';

  @override
  Map<String, dynamic> toJson() {
    return {
      if (salesOrderLineId != null) 'sales_order_line_id': salesOrderLineId,
      if (salesDeliveryLineId != null)
        'sales_delivery_line_id': salesDeliveryLineId,
      'item_id': itemId,
      if (warehouseId != null) 'warehouse_id': warehouseId,
      if (batchId != null) 'batch_id': batchId,
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
