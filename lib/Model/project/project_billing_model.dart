import '../common/json_model.dart';
import '../common/model_value.dart';

class ProjectBillingModel implements JsonModel {
  const ProjectBillingModel({
    this.id,
    this.projectId,
    this.projectMilestoneId,
    this.billingDate,
    this.billingBasis,
    this.billingAmount,
    this.salesInvoiceId,
    this.billingStatus,
    this.remarks,
    this.raw,
  });

  final int? id;
  final int? projectId;
  final int? projectMilestoneId;
  final String? billingDate;
  final String? billingBasis;
  final double? billingAmount;
  final int? salesInvoiceId;
  final String? billingStatus;
  final String? remarks;
  final Map<String, dynamic>? raw;

  factory ProjectBillingModel.fromJson(Map<String, dynamic> json) {
    return ProjectBillingModel(
      id: ModelValue.nullableInt(json['id']),
      projectId: ModelValue.nullableInt(json['project_id']),
      projectMilestoneId: ModelValue.nullableInt(json['project_milestone_id']),
      billingDate: json['billing_date']?.toString(),
      billingBasis: json['billing_basis']?.toString(),
      billingAmount: ModelValue.nullableDouble(json['billing_amount']),
      salesInvoiceId: ModelValue.nullableInt(json['sales_invoice_id']),
      billingStatus: json['billing_status']?.toString(),
      remarks: json['remarks']?.toString(),
      raw: json,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    if (projectId != null) 'project_id': projectId,
    if (projectMilestoneId != null) 'project_milestone_id': projectMilestoneId,
    if (billingDate != null) 'billing_date': billingDate,
    if (billingBasis != null) 'billing_basis': billingBasis,
    if (billingAmount != null) 'billing_amount': billingAmount,
    if (salesInvoiceId != null) 'sales_invoice_id': salesInvoiceId,
    if (billingStatus != null) 'billing_status': billingStatus,
    if (remarks != null) 'remarks': remarks,
  };
}
