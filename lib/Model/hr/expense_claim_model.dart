import '../../screen.dart';

class ExpenseClaimModel extends JsonModel {
  const ExpenseClaimModel({
    super.id,
    this.companyId,
    this.employeeId,
    this.claimNo,
    this.claimDate,
    this.totalAmount,
    this.claimStatus,
    this.voucherId,
    this.reimbursementVoucherId,
    this.notes,
    this.approvedBy,
    this.approvedAt,
    this.reimbursedBy,
    this.reimbursedAt,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  });
  final int? companyId;
  final int? employeeId;
  final String? claimNo;
  final String? claimDate;
  final double? totalAmount;
  final String? claimStatus;
  final int? voucherId;
  final int? reimbursementVoucherId;
  final String? notes;
  final int? approvedBy;
  final String? approvedAt;
  final int? reimbursedBy;
  final String? reimbursedAt;
  final int? createdBy;
  final int? updatedBy;
  final String? createdAt;
  final String? updatedAt;

  factory ExpenseClaimModel.fromJson(Map<String, dynamic> json) {
    return ExpenseClaimModel(
      id: JsonModel.nullableInt(json['id']),
      companyId: JsonModel.nullableInt(json['company_id']),
      employeeId: JsonModel.nullableInt(json['employee_id']),
      claimNo: json['claim_no']?.toString(),
      claimDate: json['claim_date']?.toString(),
      totalAmount: JsonModel.nullableDouble(json['total_amount']),
      claimStatus: json['claim_status']?.toString(),
      voucherId: JsonModel.nullableInt(json['voucher_id']),
      reimbursementVoucherId: JsonModel.nullableInt(
        json['reimbursement_voucher_id'],
      ),
      notes: json['notes']?.toString(),
      approvedBy: JsonModel.nullableInt(json['approved_by']),
      approvedAt: json['approved_at']?.toString(),
      reimbursedBy: JsonModel.nullableInt(json['reimbursed_by']),
      reimbursedAt: json['reimbursed_at']?.toString(),
      createdBy: JsonModel.nullableInt(json['created_by']),
      updatedBy: JsonModel.nullableInt(json['updated_by']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
  @override
  String toString() => 'Expense Claim';


  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (companyId != null) 'company_id': companyId,
    if (employeeId != null) 'employee_id': employeeId,
    if (claimNo != null) 'claim_no': claimNo,
    if (claimDate != null) 'claim_date': claimDate,
    if (totalAmount != null) 'total_amount': totalAmount,
    if (claimStatus != null) 'claim_status': claimStatus,
    if (voucherId != null) 'voucher_id': voucherId,
    if (reimbursementVoucherId != null)
      'reimbursement_voucher_id': reimbursementVoucherId,
    if (notes != null) 'notes': notes,
    if (approvedBy != null) 'approved_by': approvedBy,
    if (approvedAt != null) 'approved_at': approvedAt,
    if (reimbursedBy != null) 'reimbursed_by': reimbursedBy,
    if (reimbursedAt != null) 'reimbursed_at': reimbursedAt,
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
