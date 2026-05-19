import '../../screen.dart';

class ProjectVendorWorkModel extends JsonModel {
  const ProjectVendorWorkModel({
    super.id,
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
  });
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

  factory ProjectVendorWorkModel.fromJson(Map<String, dynamic> json) {
    return ProjectVendorWorkModel(
      id: JsonModel.nullableInt(json['id']),
      projectId: JsonModel.nullableInt(json['project_id']),
      projectTaskId: JsonModel.nullableInt(json['project_task_id']),
      vendorPartyId: JsonModel.nullableInt(json['vendor_party_id']),
      purchaseOrderId: JsonModel.nullableInt(json['purchase_order_id']),
      purchaseInvoiceId: JsonModel.nullableInt(json['purchase_invoice_id']),
      workDescription: json['work_description']?.toString(),
      amount: JsonModel.nullableDouble(json['amount']),
      voucherId: JsonModel.nullableInt(json['voucher_id']),
      workStatus: json['work_status']?.toString(),
      remarks: json['remarks']?.toString(),
    );
  }
  @override
  String toString() => 'Project Vendor Work';


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
