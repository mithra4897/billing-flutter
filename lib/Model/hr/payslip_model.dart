import '../../screen.dart';

class PayslipModel extends JsonModel {
  const PayslipModel({
    super.id,
    this.payrollLineId,
    this.payslipDate,
    this.generatedBy,
    this.remarks,
    this.createdAt,
    this.updatedAt,
  });
  final int? payrollLineId;
  final String? payslipDate;
  final int? generatedBy;
  final String? remarks;
  final String? createdAt;
  final String? updatedAt;

  factory PayslipModel.fromJson(Map<String, dynamic> json) {
    return PayslipModel(
      id: ModelValue.nullableInt(json['id']),
      payrollLineId: ModelValue.nullableInt(json['payroll_line_id']),
      payslipDate: json['payslip_date']?.toString(),
      generatedBy: ModelValue.nullableInt(json['generated_by']),
      remarks: json['remarks']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
  @override
  String toString() => 'Payslip';


  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (payrollLineId != null) 'payroll_line_id': payrollLineId,
    if (payslipDate != null) 'payslip_date': payslipDate,
    if (generatedBy != null) 'generated_by': generatedBy,
    if (remarks != null) 'remarks': remarks,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
