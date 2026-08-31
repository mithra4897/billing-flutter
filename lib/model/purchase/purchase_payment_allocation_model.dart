import '../../screen.dart';

class PurchasePaymentAllocationModel extends JsonModel {
  const PurchasePaymentAllocationModel({
    super.id,
    this.purchasePaymentId,
    this.purchaseInvoiceId,
    this.allocatedAmount,
    this.allocationType,
    this.remarks,
    this.isAutoAllocated,
    this.sourcePaymentId,
    this.allocatedBy,
    this.allocatedAt,
    this.createdAt,
    this.updatedAt,
  });
  final int? purchasePaymentId;
  final int? purchaseInvoiceId;
  final double? allocatedAmount;
  final String? allocationType;
  final String? remarks;
  final bool? isAutoAllocated;
  final int? sourcePaymentId;
  final int? allocatedBy;
  final String? allocatedAt;
  final String? createdAt;
  final String? updatedAt;

  factory PurchasePaymentAllocationModel.fromJson(Map<String, dynamic> json) {
    return PurchasePaymentAllocationModel(
      id: JsonModel.nullableInt(json['id']),
      purchasePaymentId: JsonModel.nullableInt(json['purchase_payment_id']),
      purchaseInvoiceId: JsonModel.nullableInt(json['purchase_invoice_id']),
      allocatedAmount: JsonModel.nullableDouble(json['allocated_amount']),
      allocationType: json['allocation_type']?.toString(),
      remarks: json['remarks']?.toString(),
      isAutoAllocated: json['is_auto_allocated'] == null
          ? null
          : JsonModel.boolOf(json['is_auto_allocated']),
      sourcePaymentId: JsonModel.nullableInt(json['source_payment_id']),
      allocatedBy: JsonModel.nullableInt(json['allocated_by']),
      allocatedAt: json['allocated_at']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
  @override
  String toString() => JsonModel.combineValues([
    allocationType,
  ], defaultValue: 'Purchase Payment Allocation');

  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (purchasePaymentId != null) 'purchase_payment_id': purchasePaymentId,
    if (purchaseInvoiceId != null) 'purchase_invoice_id': purchaseInvoiceId,
    if (allocatedAmount != null) 'allocated_amount': allocatedAmount,
    if (allocationType != null) 'allocation_type': allocationType,
    if (remarks != null) 'remarks': remarks,
    if (isAutoAllocated != null) 'is_auto_allocated': isAutoAllocated,
    if (sourcePaymentId != null) 'source_payment_id': sourcePaymentId,
    if (allocatedBy != null) 'allocated_by': allocatedBy,
    if (allocatedAt != null) 'allocated_at': allocatedAt,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
