import '../../screen.dart';

class ServiceContractAssetModel extends JsonModel {
  const ServiceContractAssetModel({
    super.id,
    this.serviceContractId,
    this.assetId,
    this.itemId,
    this.serialId,
    this.serialNo,
    this.installationDate,
    this.warrantyStartDate,
    this.warrantyEndDate,
    this.customerSiteAddress,
    this.isActive,
    this.remarks,
    this.createdAt,
    this.updatedAt,
  });
  final int? serviceContractId;
  final int? assetId;
  final int? itemId;
  final int? serialId;
  final String? serialNo;
  final String? installationDate;
  final String? warrantyStartDate;
  final String? warrantyEndDate;
  final String? customerSiteAddress;
  final bool? isActive;
  final String? remarks;
  final String? createdAt;
  final String? updatedAt;

  factory ServiceContractAssetModel.fromJson(Map<String, dynamic> json) {
    return ServiceContractAssetModel(
      id: JsonModel.nullableInt(json['id']),
      serviceContractId: JsonModel.nullableInt(json['service_contract_id']),
      assetId: JsonModel.nullableInt(json['asset_id']),
      itemId: JsonModel.nullableInt(json['item_id']),
      serialId: JsonModel.nullableInt(json['serial_id']),
      serialNo: json['serial_no']?.toString(),
      installationDate: json['installation_date']?.toString(),
      warrantyStartDate: json['warranty_start_date']?.toString(),
      warrantyEndDate: json['warranty_end_date']?.toString(),
      customerSiteAddress: json['customer_site_address']?.toString(),
      isActive: json['is_active'] == null
          ? null
          : JsonModel.boolOf(json['is_active']),
      remarks: json['remarks']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
  @override
  String toString() => 'Service Contract Asset';


  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (serviceContractId != null) 'service_contract_id': serviceContractId,
    if (assetId != null) 'asset_id': assetId,
    if (itemId != null) 'item_id': itemId,
    if (serialId != null) 'serial_id': serialId,
    if (serialNo != null) 'serial_no': serialNo,
    if (installationDate != null) 'installation_date': installationDate,
    if (warrantyStartDate != null) 'warranty_start_date': warrantyStartDate,
    if (warrantyEndDate != null) 'warranty_end_date': warrantyEndDate,
    if (customerSiteAddress != null)
      'customer_site_address': customerSiteAddress,
    if (isActive != null) 'is_active': isActive,
    if (remarks != null) 'remarks': remarks,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
