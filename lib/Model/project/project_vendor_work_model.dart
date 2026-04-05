import '../common/json_model.dart';
import '../common/model_value.dart';

class ProjectVendorWorkModel implements JsonModel {
  const ProjectVendorWorkModel({
    this.id,
    this.projectId,
    this.projectTaskId,
    this.vendorPartyId,
    this.purchaseOrderId,
    this.purchaseInvoiceId,
    this.workDescription,
    this.amount,
    this.voucherId,
    this.workStatus,
    this.remarks,
    this.raw,
  });

  final int? id;
  final int? projectId;
  final int? projectTaskId;
  final int? vendorPartyId;
  final int? purchaseOrderId;
  final int? purchaseInvoiceId;
  final String? workDescription;
  final double? amount;
  final int? voucherId;
  final String? workStatus;
  final String? remarks;
  final Map<String, dynamic>? raw;

  factory ProjectVendorWorkModel.fromJson(Map<String, dynamic> json) {
    return ProjectVendorWorkModel(
      id: ModelValue.nullableInt(json['id']),
      projectId: ModelValue.nullableInt(json['project_id']),
      projectTaskId: ModelValue.nullableInt(json['project_task_id']),
      vendorPartyId: ModelValue.nullableInt(json['vendor_party_id']),
      purchaseOrderId: ModelValue.nullableInt(json['purchase_order_id']),
      purchaseInvoiceId: ModelValue.nullableInt(json['purchase_invoice_id']),
      workDescription: json['work_description']?.toString(),
      amount: ModelValue.nullableDouble(json['amount']),
      voucherId: ModelValue.nullableInt(json['voucher_id']),
      workStatus: json['work_status']?.toString(),
      remarks: json['remarks']?.toString(),
      raw: json,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    if (projectId != null) 'project_id': projectId,
    if (projectTaskId != null) 'project_task_id': projectTaskId,
    if (vendorPartyId != null) 'vendor_party_id': vendorPartyId,
    if (purchaseOrderId != null) 'purchase_order_id': purchaseOrderId,
    if (purchaseInvoiceId != null) 'purchase_invoice_id': purchaseInvoiceId,
    if (workDescription != null) 'work_description': workDescription,
    if (amount != null) 'amount': amount,
    if (voucherId != null) 'voucher_id': voucherId,
    if (workStatus != null) 'work_status': workStatus,
    if (remarks != null) 'remarks': remarks,
  };
}
