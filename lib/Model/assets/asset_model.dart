import '../../screen.dart';

class AssetModel implements JsonModel {
  const AssetModel({
    this.id,
    this.companyId,
    this.branchId,
    this.locationId,
    this.assetCategoryId,
    this.assetCode,
    this.assetName,
    this.assetTagNo,
    this.serialNo,
    this.manufacturer,
    this.modelNo,
    this.purchaseDate,
    this.capitalizationDate,
    this.putToUseDate,
    this.purchaseInvoiceId,
    this.purchaseInvoiceLineId,
    this.supplierPartyId,
    this.assetAccountId,
    this.accumDepreciationAccountId,
    this.depreciationExpenseAccountId,
    this.costCenterId,
    this.departmentName,
    this.employeeName,
    this.warehouseId,
    this.acquisitionCost,
    this.additionalCost,
    this.capitalizationValue,
    this.salvageValue,
    this.assetStatus,
    this.conditionStatus,
    this.warrantyStartDate,
    this.warrantyEndDate,
    this.notes,
    this.activatedBy,
    this.activatedAt,
    this.disposedBy,
    this.disposedAt,
    this.isDepreciable,
    this.isActive,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
    Map<String, dynamic>? raw,
  }) : _raw = raw;

  final int? id;
  final int? companyId;
  final int? branchId;
  final int? locationId;
  final int? assetCategoryId;
  final String? assetCode;
  final String? assetName;
  final String? assetTagNo;
  final String? serialNo;
  final String? manufacturer;
  final String? modelNo;
  final String? purchaseDate;
  final String? capitalizationDate;
  final String? putToUseDate;
  final int? purchaseInvoiceId;
  final int? purchaseInvoiceLineId;
  final int? supplierPartyId;
  final int? assetAccountId;
  final int? accumDepreciationAccountId;
  final int? depreciationExpenseAccountId;
  final int? costCenterId;
  final String? departmentName;
  final String? employeeName;
  final int? warehouseId;
  final double? acquisitionCost;
  final double? additionalCost;
  final double? capitalizationValue;
  final double? salvageValue;
  final String? assetStatus;
  final String? conditionStatus;
  final String? warrantyStartDate;
  final String? warrantyEndDate;
  final String? notes;
  final int? activatedBy;
  final String? activatedAt;
  final int? disposedBy;
  final String? disposedAt;
  final bool? isDepreciable;
  final bool? isActive;
  final int? createdBy;
  final int? updatedBy;
  final String? createdAt;
  final String? updatedAt;

  factory AssetModel.fromJson(Map<String, dynamic> json) {
    return AssetModel(
      id: ModelValue.nullableInt(json['id']),
      companyId: ModelValue.nullableInt(json['company_id']),
      branchId: ModelValue.nullableInt(json['branch_id']),
      locationId: ModelValue.nullableInt(json['location_id']),
      assetCategoryId: ModelValue.nullableInt(json['asset_category_id']),
      assetCode: json['asset_code']?.toString(),
      assetName: json['asset_name']?.toString(),
      assetTagNo: json['asset_tag_no']?.toString(),
      serialNo: json['serial_no']?.toString(),
      manufacturer: json['manufacturer']?.toString(),
      modelNo: json['model_no']?.toString(),
      purchaseDate: json['purchase_date']?.toString(),
      capitalizationDate: json['capitalization_date']?.toString(),
      putToUseDate: json['put_to_use_date']?.toString(),
      purchaseInvoiceId: ModelValue.nullableInt(json['purchase_invoice_id']),
      purchaseInvoiceLineId: ModelValue.nullableInt(
        json['purchase_invoice_line_id'],
      ),
      supplierPartyId: ModelValue.nullableInt(json['supplier_party_id']),
      assetAccountId: ModelValue.nullableInt(json['asset_account_id']),
      accumDepreciationAccountId: ModelValue.nullableInt(
        json['accum_depreciation_account_id'],
      ),
      depreciationExpenseAccountId: ModelValue.nullableInt(
        json['depreciation_expense_account_id'],
      ),
      costCenterId: ModelValue.nullableInt(json['cost_center_id']),
      departmentName: json['department_name']?.toString(),
      employeeName: json['employee_name']?.toString(),
      warehouseId: ModelValue.nullableInt(json['warehouse_id']),
      acquisitionCost: ModelValue.nullableDouble(json['acquisition_cost']),
      additionalCost: ModelValue.nullableDouble(json['additional_cost']),
      capitalizationValue: ModelValue.nullableDouble(
        json['capitalization_value'],
      ),
      salvageValue: ModelValue.nullableDouble(json['salvage_value']),
      assetStatus: json['asset_status']?.toString(),
      conditionStatus: json['condition_status']?.toString(),
      warrantyStartDate: json['warranty_start_date']?.toString(),
      warrantyEndDate: json['warranty_end_date']?.toString(),
      notes: json['notes']?.toString(),
      activatedBy: ModelValue.nullableInt(json['activated_by']),
      activatedAt: json['activated_at']?.toString(),
      disposedBy: ModelValue.nullableInt(json['disposed_by']),
      disposedAt: json['disposed_at']?.toString(),
      isDepreciable: json['is_depreciable'] == null
          ? null
          : ModelValue.boolOf(json['is_depreciable']),
      isActive: json['is_active'] == null
          ? null
          : ModelValue.boolOf(json['is_active']),
      createdBy: ModelValue.nullableInt(json['created_by']),
      updatedBy: ModelValue.nullableInt(json['updated_by']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (companyId != null) 'company_id': companyId,
    if (branchId != null) 'branch_id': branchId,
    if (locationId != null) 'location_id': locationId,
    if (assetCategoryId != null) 'asset_category_id': assetCategoryId,
    if (assetCode != null) 'asset_code': assetCode,
    if (assetName != null) 'asset_name': assetName,
    if (assetTagNo != null) 'asset_tag_no': assetTagNo,
    if (serialNo != null) 'serial_no': serialNo,
    if (manufacturer != null) 'manufacturer': manufacturer,
    if (modelNo != null) 'model_no': modelNo,
    if (purchaseDate != null) 'purchase_date': purchaseDate,
    if (capitalizationDate != null) 'capitalization_date': capitalizationDate,
    if (putToUseDate != null) 'put_to_use_date': putToUseDate,
    if (purchaseInvoiceId != null) 'purchase_invoice_id': purchaseInvoiceId,
    if (purchaseInvoiceLineId != null)
      'purchase_invoice_line_id': purchaseInvoiceLineId,
    if (supplierPartyId != null) 'supplier_party_id': supplierPartyId,
    if (assetAccountId != null) 'asset_account_id': assetAccountId,
    if (accumDepreciationAccountId != null)
      'accum_depreciation_account_id': accumDepreciationAccountId,
    if (depreciationExpenseAccountId != null)
      'depreciation_expense_account_id': depreciationExpenseAccountId,
    if (costCenterId != null) 'cost_center_id': costCenterId,
    if (departmentName != null) 'department_name': departmentName,
    if (employeeName != null) 'employee_name': employeeName,
    if (warehouseId != null) 'warehouse_id': warehouseId,
    if (acquisitionCost != null) 'acquisition_cost': acquisitionCost,
    if (additionalCost != null) 'additional_cost': additionalCost,
    if (capitalizationValue != null)
      'capitalization_value': capitalizationValue,
    if (salvageValue != null) 'salvage_value': salvageValue,
    if (assetStatus != null) 'asset_status': assetStatus,
    if (conditionStatus != null) 'condition_status': conditionStatus,
    if (warrantyStartDate != null) 'warranty_start_date': warrantyStartDate,
    if (warrantyEndDate != null) 'warranty_end_date': warrantyEndDate,
    if (notes != null) 'notes': notes,
    if (activatedBy != null) 'activated_by': activatedBy,
    if (activatedAt != null) 'activated_at': activatedAt,
    if (disposedBy != null) 'disposed_by': disposedBy,
    if (disposedAt != null) 'disposed_at': disposedAt,
    if (isDepreciable != null) 'is_depreciable': isDepreciable,
    if (isActive != null) 'is_active': isActive,
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
