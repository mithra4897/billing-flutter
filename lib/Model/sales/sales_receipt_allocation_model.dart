import '../../screen.dart';

class SalesReceiptAllocationModel extends JsonModel {
  const SalesReceiptAllocationModel({
    super.id,
    this.salesReceiptId,
    this.salesInvoiceId,
    this.allocatedAmount,
    this.allocationType,
    this.remarks,
    this.createdAt,
    this.updatedAt,
  });
  final int? salesReceiptId;
  final int? salesInvoiceId;
  final double? allocatedAmount;
  final String? allocationType;
  final String? remarks;
  final String? createdAt;
  final String? updatedAt;

  factory SalesReceiptAllocationModel.fromJson(Map<String, dynamic> json) {
    return SalesReceiptAllocationModel(
      id: JsonModel.nullableInt(json['id']),
      salesReceiptId: JsonModel.nullableInt(json['sales_receipt_id']),
      salesInvoiceId: JsonModel.nullableInt(json['sales_invoice_id']),
      allocatedAmount: JsonModel.nullableDouble(json['allocated_amount']),
      allocationType: json['allocation_type']?.toString(),
      remarks: json['remarks']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
  @override
  String toString() => JsonModel.combineValues([
    allocationType,
  ], defaultValue: 'Sales Receipt Allocation');


  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (salesReceiptId != null) 'sales_receipt_id': salesReceiptId,
    if (salesInvoiceId != null) 'sales_invoice_id': salesInvoiceId,
    if (allocatedAmount != null) 'allocated_amount': allocatedAmount,
    if (allocationType != null) 'allocation_type': allocationType,
    if (remarks != null) 'remarks': remarks,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
