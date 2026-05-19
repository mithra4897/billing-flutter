import '../../screen.dart';

class VoucherAllocationModel extends JsonModel {
  const VoucherAllocationModel({
    super.id,
    this.voucherLineId,
    this.againstVoucherId,
    this.againstVoucherLineId,
    this.referenceNo,
    this.referenceDate,
    this.allocationAmount,
    this.allocationType,
    this.remarks,
    this.createdAt,
    this.updatedAt,
  });
  final int? voucherLineId;
  final int? againstVoucherId;
  final int? againstVoucherLineId;
  final String? referenceNo;
  final String? referenceDate;
  final double? allocationAmount;
  final String? allocationType;
  final String? remarks;
  final String? createdAt;
  final String? updatedAt;

  factory VoucherAllocationModel.fromJson(Map<String, dynamic> json) {
    return VoucherAllocationModel(
      id: JsonModel.nullableInt(json['id']),
      voucherLineId: JsonModel.nullableInt(json['voucher_line_id']),
      againstVoucherId: JsonModel.nullableInt(json['against_voucher_id']),
      againstVoucherLineId: JsonModel.nullableInt(
        json['against_voucher_line_id'],
      ),
      referenceNo: json['reference_no']?.toString(),
      referenceDate: json['reference_date']?.toString(),
      allocationAmount: JsonModel.nullableDouble(json['allocation_amount']),
      allocationType: json['allocation_type']?.toString(),
      remarks: json['remarks']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
  @override
  String toString() => 'Voucher Allocation';


  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (voucherLineId != null) 'voucher_line_id': voucherLineId,
    if (againstVoucherId != null) 'against_voucher_id': againstVoucherId,
    if (againstVoucherLineId != null)
      'against_voucher_line_id': againstVoucherLineId,
    if (referenceNo != null) 'reference_no': referenceNo,
    if (referenceDate != null) 'reference_date': referenceDate,
    if (allocationAmount != null) 'allocation_amount': allocationAmount,
    if (allocationType != null) 'allocation_type': allocationType,
    if (remarks != null) 'remarks': remarks,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
