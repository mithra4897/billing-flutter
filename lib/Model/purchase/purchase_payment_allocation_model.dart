import '../../screen.dart';

class PurchasePaymentAllocationModel extends JsonModel {
  const PurchasePaymentAllocationModel({
    super.id,
    this.purchasePaymentId,
    this.purchaseInvoiceId,
    this.allocatedAmount,
    this.allocationType,
    this.remarks,
    this.createdAt,
    this.updatedAt,
  });
  final int? purchasePaymentId;
  final int? purchaseInvoiceId;
  final double? allocatedAmount;
  final String? allocationType;
  final String? remarks;
  final String? createdAt;
  final String? updatedAt;

  factory PurchasePaymentAllocationModel.fromJson(Map<String, dynamic> json) {
    return PurchasePaymentAllocationModel(
      id: ModelValue.nullableInt(json['id']),
      purchasePaymentId: ModelValue.nullableInt(json['purchase_payment_id']),
      purchaseInvoiceId: ModelValue.nullableInt(json['purchase_invoice_id']),
      allocatedAmount: ModelValue.nullableDouble(json['allocated_amount']),
      allocationType: json['allocation_type']?.toString(),
      remarks: json['remarks']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
  @override
  String toString() => 'Purchase Payment Allocation';


  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (purchasePaymentId != null) 'purchase_payment_id': purchasePaymentId,
    if (purchaseInvoiceId != null) 'purchase_invoice_id': purchaseInvoiceId,
    if (allocatedAmount != null) 'allocated_amount': allocatedAmount,
    if (allocationType != null) 'allocation_type': allocationType,
    if (remarks != null) 'remarks': remarks,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
